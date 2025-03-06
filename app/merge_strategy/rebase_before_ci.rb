# frozen_string_literal: true

module MergeStrategy
  class RebaseBeforeCi
    def initialize(git:, circle:)
      @circle = circle
      @git = git
    end

    def merge(feature)
      git.rebase_main(feature.branch_name)
      if circle.run(feature.sha) == Circle::SUCCESS
        git.merge(feature.branch_name)
      end
    end

    private

    attr_reader :git, :circle
  end
end
