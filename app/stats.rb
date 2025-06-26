# frozen_string_literal: true

class Stats
  include Accessors

  class << self
    def instance(...) = @instance ||= new(...)
  end

  def initialize(config:)
    @config = config
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
      deploy_times << { time: time.now - start_time, successful: result }
    end
  end

  def start_merge(feature)
    merges_in_progress[feature] ||= time.now
  end

  def end_merge(feature, successful: true)
    deploy_times << { time: time.now - merges_in_progress[feature], successful: }
    merges_in_progress.delete(feature)
  end

  def record_ci
    start_time = time.now
    yield.tap do
      ci_times << (time.now - start_time)
    end
  end

  def summarize
    # summarize_blockages
    summarize_deploy_times
  end

  private

  attr_reader :deploys_blocked_at, :config

  def ci_times = @ci_times ||= []
  def deploy_blockages = @deploy_blockages ||= []
  def deploy_times = @deploy_times ||= []
  def merges_in_progress = @merges_in_progress ||= {}

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
    successes = deploy_times.filter_map { it[:time] if it[:successful] }
    failures = deploy_times.filter_map { it[:time] unless it[:successful] }
    all_times = successes + failures

    puts 'Parameters:'
    puts "  Duration:    #{config.duration.to_words}"
    puts "  Flakiness:   #{(config.flakiness * 100).to_i}%"
    puts "  CI run time: #{config.ci_run_time.to_words}"
    puts ''
    puts 'Results:'
    puts "  Total merge attempts:   #{deploy_times.count}"
    puts "  Successful merges:      #{successes.count}"
    puts "  Failed merges:          #{failures.count}"
    puts "  Average time to deploy: #{(all_times.sum / all_times.count).to_words}"
    puts "  Max time to deploy:     #{all_times.max.to_words}"
  end
end
