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

  def initialize(auto:, features:, persist_log:, rebase:)
    @rebase = rebase

    @circle = Circle.new
    @git_client = GitClient.new
    @printer = Printer.new(circle, tail: auto, persist: persist_log, show_commands: !auto)

    printer.print_output

    if auto
      features.times.map { create_feature }
        .map(&:simulate!)
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

  attr_reader :features, :git_client, :printer, :circle, :rebase

  private

  def merge_strategy = MergeStrategy::RebaseBeforeCi.new(git: git_client, circle:)
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
