# frozen_string_literal: true

class Git
  def initialize
    @main = Branch.new(self, name: 'main').tap { it.create_commit }
    @branches = []
  end

  def create_branch
    Branch.new(self, from_branch: main).tap { branches << it }
  end

  attr_reader :main, :branches
end
