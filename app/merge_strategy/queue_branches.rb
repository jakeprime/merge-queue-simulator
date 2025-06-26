# frozen_string_literal: true

require 'memery'

require_relative '../file_logger'

module MergeStrategy
  class QueueBranches
    include Accessors
    include Memery

    def initialize
      @merge_branches = []
    end

    def merge(feature)
      merge_branch = branch_name
      stats.start_merge(feature.branch_name)

      git.create_branch(merge_branch, start_point: feature.branch_name)
      git.rebase(merge_branch, onto: merge_branches.last || 'main')

      merge_branches << merge_branch

      sha = git.sha(merge_branch)

      circle.run(sha)
      successful = circle.status(sha) == Circle::SUCCESS

      if successful
        handle_success(merge_branch, feature)
      else
        handle_failure(merge_branch, feature)
      end
      successful
    end

    private

    def mutex = Mutex.new
    memoize :mutex

    def count
      @count ||= 0
      @count += 1
    end

    def handle_success(merge_branch, feature)
      # wait while branch is still in the queue
      Thread.new do
        sleep(0.1) while merge_branches.index(merge_branch)&.positive?
      end.join

      return false unless merge_branches.first == merge_branch

      mutex.synchronize do
        git.delete_branch(merge_branch)
        git.rebase_main(feature.branch_name)
        git.merge(feature.branch_name)
        merge_branches.shift
      end
      stats.end_merge(feature.branch_name)
    end

    def handle_failure(branch_name, feature)
      position = merge_branches.index(branch_name)

      merge_branches.slice!(position..-1) if position
      git.delete_branch(branch_name) # and the repo

      # if this wasn't the first feature in the queue than the failure was likely
      # from a previous commit, so try again

      if position&.zero?
        stats.end_merge(feature.branch_name, successful: false)
      else
        merge(feature)
      end
    end

    def branch_name = "merge-queue-#{count}"

    attr_accessor :merge_branches
  end
end
