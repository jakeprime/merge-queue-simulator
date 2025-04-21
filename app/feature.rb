# frozen_string_literal: true

class Feature
  include Accessors
  include Memery

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

  def initialize(merge_strategy:, create_branch: false, create_commit: false, rebase: false)
    @merge_strategy = merge_strategy
    @rebase = rebase

    self.create_branch if create_branch || create_commit
    self.create_commit if create_commit

    self.class.all << self
  end

  def simulate!(in_about:, commits:)
    @thread = Thread.new do
      time.in_about(in_about) { create_branch }
      make_some_commits(commits)
      time.in_up_to(1.hour) { attempt_merge }
    end

    self
  end

  def ci_result = Random.rand < 0.3 ? Circle::FAILURE : Circle::SUCCESS
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

  def branch_name
    jira = 3.times.map { ('A'..'Z').to_a.sample }.join
    verb = %w[create change add remove].sample
    squad = %w[ewa cbc partners voice ci onboarding fraud].sample
    noun = %w[plan conditions waitlist test].sample

    [jira, count, verb, squad, noun].join('-')
  end
  memoize :branch_name

  def count
    @count ||= 101
    @count += 1
  end

  private

  attr_reader :thread, :merge_strategy

  def rebase? = @rebase

  def create_branch
    printer.status = "Creating branch - #{branch_name}"

    @sha = git.create_branch(branch_name)
  end

  def make_some_commits(commits)
    (1..commits).to_a.sample.times do
      time.in_up_to(1.hour) do
        create_commit
      end
    end
  end
end
