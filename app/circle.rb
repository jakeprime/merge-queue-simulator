# frozen_string_literal: true

require 'digest'

class Circle
  include TimeSimulator

  IN_PROGRESS = :in_progress
  SUCCESS = :success
  FAILURE = :failure

  def initialize(git:)
    @git = git
    @test_results = {}
  end

  attr_accessor :printer
  attr_reader :test_results

  def run(sha, result: random_result)
    return test_results[sha] if test_results[sha]

    test_results[sha] = IN_PROGRESS

    in_about(10.minutes) do
      test_results[sha] = parents_passing?(sha) ? result : FAILURE
    end
  end

  def status(sha)
    key = test_results.keys.find { it.index(sha) }
    test_results[key]
  end

  private

  def parents_passing?(sha)
    return true
    # if any of the parents will fail then so will this so check them first
    git.parents(sha).each do |parent|
      next unless status(parent) # don't want to check every commit, just the branch points
      return false if sha_to_result(parent) == FAILURE
    end

    true
  end

  def random_result = Random.rand < 0.3 ? Circle::FAILURE : Circle::SUCCESS

  def sha_to_result(sha)
    # determinisitally get a random result using the commit message
    hash = Digest::MD5.hexdigest(git.commit_message(sha))
    normalized = hash.to_i(16).to_f / 2**128 # gives a value 0..1

    normalized < 0.3 ? FAILURE : SUCCESS
  end

  attr_reader :git
end
