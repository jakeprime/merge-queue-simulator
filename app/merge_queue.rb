# frozen_string_literal: true

require_relative '../lib/time_helper'
require_relative '../lib/time_simulator'

require_relative 'branch'
require_relative 'feature'
require_relative 'git'

class MergeQueue
  def initialize
    puts 'Merge queue simulator'

    Feature.new(git)
  end

  def git = @git ||= Git.new
end
