# frozen_string_literal: true

require 'digest'

class Circle
  include Accessors

  IN_PROGRESS = :in_progress
  SUCCESS = :success
  FAILURE = :failure

  class << self
    def instance(...) = @instance ||= new(...)
  end

  def initialize(config:)
    @results_by_sha = {}
    @results_by_commit = {}
    @config = config
  end

  attr_accessor :printer
  attr_reader :test_results

  def run(sha, result: nil)
    # this is the result the individual commit should always resolve to
    result ||= sha_to_result(sha)
    set_commit_status(sha, result)

    # the sha also depends on parents
    set_sha_status(sha, IN_PROGRESS)

    stats.record_ci do
      time.in_about(config.ci_run_time, 0.1) do
        set_sha_status(sha, parents_passing?(sha) ? result : FAILURE)
      end
    end
  end

  def status(sha)
    short_sha = sha[0...7]
    results_by_sha[short_sha] || results_by_commit[git.commit_message(sha)]
  end

  def in_progress = results_by_sha.filter_map { |k, v| k if v == IN_PROGRESS }
  def successes = results_by_sha.filter_map { |k, v| k if v == SUCCESS }
  def failures = results_by_sha.filter_map { |k, v| k if v == FAILURE }

  private

  def set_sha_status(sha, status)
    short_sha = sha[0...7]
    results_by_sha[short_sha] = status
  end

  def set_commit_status(sha, status)
    results_by_commit[git.commit_message(sha)] = status
  end

  def parents_passing?(sha)
    # if any of the parents will fail then so will this so check them first
    git.parents(sha).all? do |parent_sha|
      next false if results_by_commit[git.commit_message(parent_sha)] == FAILURE
      next false if results_by_sha[parent_sha] == FAILURE

      true
    end
  end

  def random_result = Random.rand < 0.0 ? Circle::FAILURE : Circle::SUCCESS

  def sha_to_result(sha)
    # determinisitally get a random result using the commit message
    hash = Digest::MD5.hexdigest(git.commit_message(sha))
    normalized = hash.to_i(16).to_f / (2**128) # gives a value 0..1

    return FAILURE if Random.rand < config.flakiness

    normalized < 0.0 ? FAILURE : SUCCESS
  end

  attr_reader :results_by_sha, :results_by_commit, :config
end
