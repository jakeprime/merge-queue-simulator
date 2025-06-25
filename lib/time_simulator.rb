# frozen_string_literal: true

class TimeSimulator
  TIME_STEP = 60.seconds
  CLOCK_TICK = 0.01

  class << self
    def instance = @instance ||= new
  end

  def initialize
    @timer = 0
    @locks = Hash.new(false)
    @mutex = Mutex.new

    start_clock
  end

  def start_clock
    Thread.new do
      loop do
        sleep(CLOCK_TICK)

        break if stop?
        next if paused?

        @timer += TIME_STEP
      end
    end
  end

  def stop_clock
    @stop = true
  end

  def pause
    return yield if @locks[Thread.current]

    mutex.synchronize do
      @locks[Thread.current] = true
      yield.tap do
        @locks[Thread.current] = false
      end
    end
  end

  def now = @timer

  def paused? = @locks.values.compact.any?
  def stop? = @stop

  def in_about(time)
    # randomly vary from 75% to 125% of given time value
    random_variation = (Random.rand * 0.5) + 0.75
    wait_for(time * random_variation)

    yield
  end

  def in(time)
    wait_for(time)
    yield
  end

  def wait_for(time)
    target_time = time + timer

    loop do
      sleep(CLOCK_TICK)

      break if timer > target_time
    end
  end

  def in_up_to(time)
    # randomly vary up to a maximum time
    random_variation = Random.rand
    wait_for(time * random_variation)

    yield
  end

  attr_reader :timer, :paused, :stop, :mutex
end
