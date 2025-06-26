# frozen_string_literal: true

class Numeric
  def seconds = self
  def minutes = seconds * 60
  def minute = minutes
  def hours = minutes * 60
  def hour = hours
  def days = hours * 8
  def day = days
  def weeks = days * 5
  def week = weeks

  def in_minutes = seconds.to_f / 60
  def in_hours = in_minutes / 60
  def in_days = in_hours / 8
  def in_weeks = in_days / 5

  def to_words
    return "#{seconds.round(1)} seconds" if self < 1.minute
    return "#{in_minutes.round(1)} minutes" if self < 1.hour
    return "#{in_hours.round(1)} hours" if self < 1.day
    return "#{in_days.round(1)} days" if self < 1.week

    "#{in_weeks.round(1)} weeks"
  end
end
