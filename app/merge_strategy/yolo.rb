# frozen_string_literal: true

module MergeStrategy
  class Yolo
    include Accessors

    def merge(feature)
      git.merge(feature.branch_name)
      sha = git.sha('main')
      stats.record_merge do
        circle.run(sha)
        circle.status(sha) == Circle::SUCCESS
      end
    end
  end
end
