# frozen_string_literal: true

require 'colorize'

require_relative '../lib/time_helper'
require_relative '../lib/time_simulator'

require_relative 'branch'
require_relative 'feature'
require_relative 'git'

class MergeQueue
  def initialize
    puts 'Merge queue simulator'

    features = 2.times.map { Feature.new(git) }
    features.each(&:wait_for_me)
  end

  def git = @git ||= Git.new
end
