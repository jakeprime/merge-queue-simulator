# frozen_string_literal: true

class Feature
  include TimeSimulator

  def initialize(git)
    @git = git

    @thread = Thread.new do
      in_about(10.minutes) { create_branch }
      make_some_commits
      in_about(10.minutes) { attempt_merge }
    end
  end

  def wait_for_me
    thread.join
  end

  private

  attr_reader :branch, :git, :thread

  def create_branch
    @branch = git.create_branch
  end

  def make_some_commits
    (1..3).to_a.sample.times { branch.create_commit }
  end

  def attempt_merge
    return unless branch.pass_ci?

    branch.merge

    puts "Creating commit - #{branch.name_in_color}:#{branch.head}"
  end
end
