# frozen_string_literal: true

class TimeRecorder
  include Singleton

  class << self
    delegate :record_time_to_deploy, to: :instance
  end

  def record_time_to_deploy(time)
    deploy_times << time
  end
end
