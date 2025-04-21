# frozen_string_literal: true

module MergeStrategy
  class Yolo
    include Accessors

    def merge(feature)
      git.merge(feature.branch_name)
      sha = git.sha('main')
      circle.run(sha)
    end
  end
end
