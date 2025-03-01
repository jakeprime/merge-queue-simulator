# frozen_string_literal: true

module TimeSimulator
  TIME_SCALE = 1 / 60

  def in_about(time)
    sleep(time * TIME_SCALE)

    yield
  end
end
