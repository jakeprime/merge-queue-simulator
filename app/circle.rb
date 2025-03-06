# frozen_string_literal: true

class Circle
  include TimeSimulator

  IN_PROGRESS = :in_progress
  SUCCESS = :success
  FAILURE = :failure

  def initialize
    @test_results = {}
  end

  attr_accessor :printer
  attr_reader :test_results

  def run(sha)
    return test_results[sha] if test_results[sha]

    test_results[sha] = IN_PROGRESS

    in_about(10.minutes) do
      test_results[sha] = Random.rand > -0.3 ? SUCCESS : FAILURE
    end
  end

  def status(sha)
    key = test_results.keys.find { it.index(sha) }
    test_results[key]
  end
end
