# frozen_string_literal: true

require 'digest'

class Circle
  include TimeSimulator

  IN_PROGRESS = :in_progress
  SUCCESS = :success
  FAILURE = :failure

  def initialize(git:)
    @git = git
    @results_by_sha = {}
    @results_by_commit = {}
  end

  attr_accessor :printer
  attr_reader :test_results

  def run(sha, result: random_result)
    # this is the result the individual commit should always resolve to
    set_commit_status(sha, result)

    # the sha also depends on parents
    set_sha_status(sha, IN_PROGRESS)

    in_about(10.minutes) do
      set_sha_status(sha, parents_passing?(sha) ? result : FAILURE)
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
    git.parents(sha).none? { results_by_commit[git.commit_message(sha)] == FAILURE }
  end

  def random_result = Random.rand < 0.3 ? Circle::FAILURE : Circle::SUCCESS

  def sha_to_result(sha)
    # determinisitally get a random result using the commit message
    hash = Digest::MD5.hexdigest(git.commit_message(sha))
    normalized = hash.to_i(16).to_f / 2**128 # gives a value 0..1

    normalized < 0.3 ? FAILURE : SUCCESS
  end

  attr_reader :git, :results_by_sha, :results_by_commit
end
