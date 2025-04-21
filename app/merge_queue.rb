# frozen_string_literal: true

require 'colorize'
require 'io/console'
require 'memery'

require_relative '../lib/time_helper'
require_relative '../lib/time_simulator'

require_relative 'accessors'
require_relative 'circle'
require_relative 'config'
require_relative 'feature'
require_relative 'git_client'
require_relative 'merge_strategy'
require_relative 'printer'

class MergeQueue
  include Accessors
  include Memery
  include TimeSimulator

  def call
    init_services
    printer.print_output

    if auto?
      features.times
        .map do |count|
          create_feature.tap { it.simulate!(in_about: count.hours, commits:) }
      end
        .map(&:wait_for_completion)
      git.create_commit('main')
    else
      loop do
        char = $stdin.getch
        perform_action(char) if char

        break if char&.downcase == 'q'
      end
    end

    printer.stop
    git.teardown
  end

  def config
    @config ||= Config.default
    yield @config if block_given?
    @config
  end

  private

  delegate :auto, :commits, :features, :strategy, to: :config

  def auto? = auto

  def init_services
    GitClient.instance
    Circle.instance
    Printer.init(config:)
  end

  def merge_strategy
    {
      'yolo' => MergeStrategy::Yolo.new,
      'rebase' => MergeStrategy::RebaseBeforeCi.new,
      'mq' => MergeStrategy::QueueBranches.new,
      'sq' => MergeStrategy::HoldingPen.new,
    }[strategy]
  end
  memoize :merge_strategy

  def create_feature = Feature.new(merge_strategy:)

  def perform_action(char)
    case char.downcase
    when 'b'
      Feature.new(merge_strategy:, create_commit: true)
    when 'c'
      Feature.create_commit
    when 'm'
      Thread.new { Feature.merge_branch; printer.print_output }
    end

    printer.print_output
  end
end
