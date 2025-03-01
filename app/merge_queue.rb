# frozen_string_literal: true

require_relative '../lib/time_helper'
require_relative '../lib/time_simulator'

require_relative 'feature'
require_relative 'git_client'
require_relative 'printer'

class MergeQueue
  include TimeSimulator

  def initialize
    puts 'Merge queue simulator'

    git_client = GitClient.new
    printer = Printer.new

    features = 3.times.map { Feature.new(git_client, printer) }

    features.each(&:wait_for_completion)

    printer.stop
    git_client.teardown
  end
end
