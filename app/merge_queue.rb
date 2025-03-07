# frozen_string_literal: true

require 'colorize'
require 'io/console'
require 'memery'

require_relative '../lib/time_helper'
require_relative '../lib/time_simulator'

require_relative 'circle'
require_relative 'feature'
require_relative 'git_client'
require_relative 'merge_strategy'
require_relative 'printer'

class MergeQueue
  include Memery
  include TimeSimulator

  def initialize(auto:, commits:, features:, persist_log:, strategy: 'sq')
    @strategy = strategy

    @git_client = GitClient.new
    @circle = Circle.new(git: git_client)
    @printer = Printer.new(circle, tail: auto, persist: persist_log, show_commands: !auto)

    printer.print_output

    if auto
      features.times
        .map do |count|
          create_feature.tap { it.simulate!(in_about: count.hours, commits:) }
      end
        .map(&:wait_for_completion)
    else
      loop do
        char = $stdin.getch
        perform_action(char) if char

        break if char&.downcase == 'q'
      end
    end

    printer.stop
    git_client.teardown
  end

  attr_reader :features, :git_client, :printer, :circle, :strategy

  private

  def merge_strategy
    {
      'yolo' => MergeStrategy::Yolo.new(git: git_client, circle:),
      'rebase' => MergeStrategy::RebaseBeforeCi.new(git: git_client, circle:),
      'mq' => MergeStrategy::QueueBranches.new(git: git_client, circle:),
      'sq' => MergeStrategy::HoldingPen.new(git: git_client, circle:),
    }[strategy]
  end
  memoize :merge_strategy

  def create_feature = Feature.new(git_client, printer, circle, merge_strategy:)

  def perform_action(char)
    case char.downcase
    when 'b'
      Feature.new(git_client, printer, circle, merge_strategy:, create_commit: true)
    when 'c'
      Feature.create_commit
    when 'm'
      Thread.new { Feature.merge_branch; printer.print_output }
    end

    printer.print_output
  end
end
