# frozen_string_literal: true

module TimeSimulator
  TIME_SCALE = 1.0 / 300

  def in_about(time)
    # randomly vary from 75% to 125% of given time value
    random_variation = (Random.rand * 0.5) + 0.75
    sleep(time * TIME_SCALE * random_variation)

    yield
  end

  def in_up_to(time)
    # randomly vary from 50% to 150% of given time value
    random_variation = Random.rand
    sleep(time * TIME_SCALE * random_variation)

    yield
  end

end
