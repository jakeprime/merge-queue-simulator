# frozen_string_literal: true

class Branch
  def initialize(git, name: generate_name, from_branch: nil)
    @git = git
    @name = name
    @commits = []
    @base = from_branch&.head

    puts "Creating new branch - #{name}"
  end

  def create_commit
    sha = generate_sha
    puts "Creating commit - #{name}:#{sha}"

    commits.push(sha)
  end

  def head = commits.last

  attr_reader :git, :commits, :name, :base

  private

  def generate_sha = 8.times.map { (('a'..'f').to_a + ('0'..'9').to_a).sample }.join
  def generate_name = "branch-#{Random.random_number(9999)}"
end
