# frozen_string_literal: true

class Feature
  include TimeSimulator

  def initialize(git, printer)
    @git = git
    @printer = printer

    @thread = Thread.new do
      in_about(10.minutes) { create_branch }
      make_some_commits
      in_about(10.minutes) { attempt_merge }
    end
  end

  def wait_for_completion
    thread.join
  end

  private

  attr_reader :git, :thread, :printer

  def branch_name = @branch_name ||= "feature-#{Random.rand(9999)}"

  def create_branch
    printer.status = "Creating branch - #{branch_name}"

    git.create_branch(branch_name)
  end

  def make_some_commits
    (1..3).to_a.sample.times do
      in_about(1.minutes) do
        printer.status = "Creating commit on #{branch_name}"
        git.create_commit(branch_name)
      end
    end
  end

  def attempt_merge
    git.merge(branch_name)
    # return unless branch.pass_ci?

    # branch.merge

    # printer.status = "Creating commit - #{branch.name_in_color}:#{branch.head}"
  end
end
