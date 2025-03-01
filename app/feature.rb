# frozen_string_literal: true

class Feature
  include TimeSimulator
  def initialize(git)
    @git = git

    in_about(10.minutes) { create_branch }
    make_some_commits
    in_about(10.minutes) { merge_branch }
  end

  private

  attr_reader :branch, :git

  def create_branch
    @branch = git.create_branch
  end

  def make_some_commits
    (1..3).to_a.sample.times { branch.create_commit }
  end

  def merge_branch = nil
end
