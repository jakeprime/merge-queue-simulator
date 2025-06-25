# frozen_string_literal: true

class Stats
  include Accessors

  class << self
    def instance = @instance ||= new
  end

  def block_deploys
    return if deploys_blocked_at

    @deploys_blocked_at = time.now
  end

  def unblock_deploys
    return unless deploys_blocked_at

    deploy_blockages << (time.now - deploys_blocked_at)
    @deploys_blocked_at = nil
  end

  def record_merge
    start_time = time.now
    yield.tap do |result|
      deploy_times << { time: time.now - start_time, successful: result}
    end
  end

  def record_ci
    start_time = time.now
    yield.tap do
      ci_times << (time.now - start_time)
    end
  end

  def summarize
    summarize_blockages
    summarize_deploy_times
  end

  private

  attr_reader :deploys_blocked_at

  def ci_times = @ci_times ||= []
  def deploy_blockages = @deploy_blockages ||= []
  def deploy_times = @deploy_times ||= []

  def summarize_blockages
    unblock_deploys

    return if deploy_blockages.none?

    puts "Deploys blocked for #{(deploy_blockages.sum / deploy_blockages.count).in_minutes} minutes"
  end

  def summarize_ci_times
    average_ci_time = ci_times.sum / ci_times.count
    puts "Average CI time #{average_ci_time.in_minutes} minutes"
  end

  def summarize_deploy_times
    times = deploy_times.filter_map { it[:time] if it[:successful] }

    if times.none?
      puts 'No successful deploys'
    else
      average_deploy_time = times.sum / times.count
      puts "Average from merge to deploy #{average_deploy_time.in_minutes} minutes"
    end
  end
end
