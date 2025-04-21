# frozen_string_literal: true

module MergeStrategy
  class RebaseBeforeCi
    include Accessors

    def merge(feature)
      git.rebase_main(feature.branch_name)
      if circle.run(feature.sha) == Circle::SUCCESS
        git.merge(feature.branch_name)
      end
    end
  end
end
