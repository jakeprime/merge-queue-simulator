# frozen_string_literal: true

require_relative '../file_logger'

# create a new branch for each feature
# rebase each one on the head of the previous
# run ci
# merge in order when successful
# deal with failures later
module MergeStrategy
  class QueueBranches
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
      if circle.run(sha) == Circle::SUCCESS
        handle_success(merge_branch, feature.branch_name)
      else
        handle_failure(merge_branch)
      end
    end

    private

    def count
      @count ||= 0
      @count += 1
    end

    def handle_success(merge_branch, feature_branch)
      Thread.new do
        loop do
          break unless merge_branches.include?(merge_branch)

          if merge_branch == merge_branches.first
            git.rebase_main(merge_branch)
            git.merge(merge_branch)
            git.delete_branch(feature_branch)
            break
          end

          sleep(1)
        end
      end.join

      merge_branches.shift
    end

    def handle_failure(branch_name)
      # ditch the current and all following queues
      @merge_queues = merge_queues[0...(merge_queues.index(branch_name))]
    end

    def branch_name = "merge-queue-#{count}"

    attr_reader :git, :circle, :merge_branches
  end
end
