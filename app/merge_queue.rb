# frozen_string_literal: true

require 'io/console'

require_relative '../lib/time_helper'
require_relative '../lib/time_simulator'

require_relative 'feature'
require_relative 'git_client'
require_relative 'printer'

class MergeQueue
  include TimeSimulator

  def initialize
    @git_client = GitClient.new
    @printer = Printer.new(show_commands: true)

    @features = []

    loop do
      char = $stdin.getch
      perform_action(char) if char

      break if char&.downcase == 'q'
    end

    # features = 3.times.map { Feature.new(git_client, printer) }
    # Feature.all.each(&:wait_for_completion)

    printer.stop
    git_client.teardown
  end

  attr_reader :features, :git_client, :printer

  private

  def perform_action(char)
    case char.downcase
    when 'b'
      Feature.new(git_client, printer, create_branch: true, create_commit: true)
    when 'c'
      Feature.create_commit
    when 'm'
      Feature.merge_branch
    end

    printer.print_output
  end
end
