# frozen_string_literal: true

class Branch
  CI_FAIL_CHANCE = 1.0 / 3

  def initialize(git, name: generate_name, from_branch: nil)
    @git = git
    @name = name
    @commits = []
    @base = from_branch&.head

    puts "Creating new branch - #{name}"
  end

  def create_commit(sha: generate_sha)
    commits.push(sha)
  end

  def pass_ci?
    success = Random.rand > CI_FAIL_CHANCE

    result = success ? 'success'.green : 'fail'.red

    puts "CI run - #{result}"
    success
  end

  def merge
    @merge_commit = generate_sha
    puts "Merging #{name}:#{merge_commit} into main"

    git.main.create_commit(sha: merge_commit)
  end

  def head = commits.last

  attr_reader :git, :commits, :name, :base, :merge_commit

  private

  def generate_sha = 8.times.map { (('a'..'f').to_a + ('0'..'9').to_a).sample }.join
  def generate_name = "branch-#{Random.random_number(9999)}"
end
