# frozen_string_literal: true

class Numeric
  def seconds = self
  def minutes = seconds * 60
  def minute = minutes
  def hours = minutes * 60
  def hour = hours
  def days = hours * 24
  def day = days

  def in_minutes = seconds / 60
  def in_hours = in_minutes / 60
  def in_days = in_hours / 24
end
