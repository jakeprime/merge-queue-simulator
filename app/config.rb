# frozen_string_literal: true

class Config
  def self.default
    new.tap do |config|
      config.auto = true
      config.ci_run_time = 10.minutes
      config.commits = 3
      config.duration = 1.day
      config.features = 3
      config.merges_per_day = 10
      config.persist_log = false
      config.silent = false
      config.strategy = 'mq'
    end
  end

  attr_accessor :auto, :ci_run_time, :commits, :features, :merges_per_day, :persist_log, :silent, :strategy, :duration
end
