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

  def in_minutes = seconds / 60
  def in_hours = in_minutes / 60
  def in_days = in_hours / 8
end
