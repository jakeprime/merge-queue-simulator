# frozen_string_literal: true

class Feature
  include Memery
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

  def initialize(git, printer, circle, merge_strategy:, create_branch: false, create_commit: false, rebase: false)
    @git = git
    @printer = printer
    @circle = circle
    @merge_strategy = merge_strategy
    @rebase = rebase

    self.create_branch if create_branch || create_commit
    self.create_commit if create_commit

    self.class.all << self
  end

  def simulate!
    @thread = Thread.new do
      in_up_to(10.minutes) { create_branch }
      make_some_commits
      in_up_to(10.minutes) { attempt_merge }
    end

    self
  end

  def ci_result = Random.rand < -0.1 ? Circle::FAILURE : Circle::SUCCESS
  memoize :ci_result

  def wait_for_completion
    thread&.join
  end

  def merging? = @merging

  def create_commit
    printer.status = "Creating commit on #{branch_name}"
    git.create_commit(branch_name)
  end

  # this will take some time, don't wait on it synchronously
  def attempt_merge
    printer.status = "Attempting merge on #{branch_name} (#{sha})"
    @merging = true

    merge_strategy.merge(self)
    printer.status = 'Merging attempt completed'
  end

  def circle_ci_status = circle.status(sha)
  def sha = git.sha(branch_name)
  def branch_name = @branch_name ||= "feature-#{Random.rand(9999)}"

  private

  attr_reader :git, :thread, :printer, :circle, :merge_strategy

  def rebase? = @rebase

  def create_branch
    printer.status = "Creating branch - #{branch_name}"

    @sha = git.create_branch(branch_name)
  end

  def make_some_commits
    (1..3).to_a.sample.times do
      in_up_to(10.minutes) do
        create_commit
      end
    end
  end
end
