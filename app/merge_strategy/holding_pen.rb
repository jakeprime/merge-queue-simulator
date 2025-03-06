# frozen_string_literal: true

require 'memery'

require_relative '../file_logger'

module MergeStrategy
  class HoldingPen
    include Memery

    def initialize(git:, circle:)
      @circle = circle
      @git = git

      @ci_running = false
      @waiting = []
    end

    def merge(feature)
      waiting.push(feature)

      run_next_queue
    end

    def run_next_queue
      mutex.synchronize do
        return if ci_running?
        @ci_running = true
      end

      while waiting.any?
        queue = waiting.dup
        @waiting = []

        merge_branch = branch_name
        git.create_branch(merge_branch)
        queue.each do |feature|
          git.rebase_main(feature.branch_name)
          git.rebase(feature.branch_name, onto: merge_branch)
          git.merge(feature.branch_name, onto: merge_branch)
        end

        circle.run(git.sha(merge_branch))

        git.merge(merge_branch, no_ff: false)

        queue.each { git.delete_branch(it.branch_name) }
      end

      @ci_running = false
    end

    private

    def ci_running? = @ci_running

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
    attr_reader :git, :circle, :waiting
  end
end
