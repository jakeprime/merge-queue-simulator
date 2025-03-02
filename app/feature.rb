# frozen_string_literal: true

class Feature
  include TimeSimulator

  @all = []

  class << self
    attr_reader :all

    def create_commit
      all.reject(&:merging?).sample&.create_commit
    end

    def merge_branch
      all.reject(&:merging?).sample&.attempt_merge
    end
  end

  def initialize(git, printer, create_branch: false, create_commit: false)
    @git = git
    @printer = printer

    self.create_branch if create_branch || create_commit
    self.create_commit if create_commit

    self.class.all << self
  end

  def simulate!
    @thread = Thread.new do
      in_about(10.minutes) { create_branch }
      make_some_commits
      in_about(10.minutes) { attempt_merge }
    end
  end

  def wait_for_completion
    thread&.join
  end

  def merging? = @merging

  def create_commit
    printer.status = "Creating commit on #{branch_name}"
    git.create_commit(branch_name)
  end

  def attempt_merge
    @merging = true
    git.merge(branch_name)
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
        create_commit
      end
    end
  end
end
