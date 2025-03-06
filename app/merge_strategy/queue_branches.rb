# frozen_string_literal: true

require 'memery'

require_relative '../file_logger'

# create a new branch for each feature
# rebase each one on the head of the previous
# run ci
# merge in order when successful
# deal with failures later
module MergeStrategy
  class QueueBranches
    include Memery

    def initialize(git:, circle:)
      @circle = circle
      @git = git

      @merge_branches = []
    end

    def merge(feature)
      merge_branch = branch_name
      git.create_branch(merge_branch, start_point: feature.branch_name)
      git.rebase(merge_branch, onto: (merge_branches.last || 'main'))

      merge_branches << merge_branch

      sha = git.sha(merge_branch)

      result = circle.run(sha, result: feature.ci_result)

      if result == Circle::SUCCESS
        handle_success(merge_branch, feature)
      else
        handle_failure(merge_branch, feature)
      end
    end

    private

    def mutex = Mutex.new
    memoize :mutex

    def count
      @count ||= 0
      @count += 1
    end

    def handle_success(merge_branch, feature)
      Thread.new do
        success = loop do
          mutex.synchronize do
            break false unless merge_branches.include?(merge_branch)

            if merge_branch == merge_branches.first
              git.rebase_main(merge_branch) # give us a nice merge bubble please
              git.merge(merge_branch)
              merge_branches.shift
              git.delete_branch(feature.branch_name)
              break true
            end
          end

          sleep(1)
        end
        handle_failure(merge_branch, feature) unless success
      end.join
    end

    def handle_failure(branch_name, feature)
      position = merge_branches.index(branch_name)

      merge_branches.slice!(position..-1) if position
      git.delete_branch(branch_name) # and the repo

      # if this wasn't the first feature in the queue than the failure was likely
      # from a previous commit, so try again
      return if position&.zero?
      merge(feature)
    end

    def branch_name = "merge-queue-#{count}"

    attr_accessor :merge_branches
    attr_reader :git, :circle
  end
end
