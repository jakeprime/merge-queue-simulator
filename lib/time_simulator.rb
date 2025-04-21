# frozen_string_literal: true

class TimeSimulator
  TIME_STEP = 1.seconds
  TIME_SPEED = 6_000
  CLOCK_TICK = 1.0 / (TIME_STEP * TIME_SPEED)

  class << self
    def instance = @instance ||= new
  end

  def initialize
    @timer = 0
    @paused = false
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
    mutex.synchronize do
      @paused = true
      result = yield
      @paused = false

      result
    end
  end

  def now = @timer

  def paused? = @paused
  def stop? = @stop

  def in_about(time)
    # randomly vary from 75% to 125% of given time value
    random_variation = (Random.rand * 0.5) + 0.75
    wait_for(time * random_variation)

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
