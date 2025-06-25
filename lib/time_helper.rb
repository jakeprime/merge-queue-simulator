# frozen_string_literal: true

class Numeric
  def seconds = self
  def minutes = seconds * 60
  def minute = minutes
  def hours = minutes * 60
  def hour = hours
  def days = hours * 8
  def day = days
  def week = days * 5

  def in_minutes = seconds.to_f / 60
  def in_hours = in_minutes.to_f / 60
  def in_days = in_hours.to_f / 8
end
