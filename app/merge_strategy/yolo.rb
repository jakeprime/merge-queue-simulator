# frozen_string_literal: true

module MergeStrategy
  class Yolo
    def initialize(git:, circle:)
      @circle = circle
      @git = git
    end

    def merge(feature)
      if circle.run(feature.sha) == Circle::SUCCESS
        git.merge(feature.branch_name)
      end
    end

    private

    attr_reader :git, :circle
  end
end
