# frozen_string_literal: true

class Config
  def self.default
    new.tap do |config|
      config.auto = true
      config.commits = 3
      config.features = 3
      config.persist_log = false
      config.silent = true
      config.strategy = 'sq'
    end
  end

  attr_accessor :auto, :commits, :features, :persist_log, :silent, :strategy
end
