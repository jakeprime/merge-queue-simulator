# frozen_string_literal: true

module MergeStrategy
  class Yolo
    include Accessors

    def merge(feature)
      if circle.run(feature.sha) == Circle::SUCCESS
        git.merge(feature.branch_name)
      end
    end
  end
end
