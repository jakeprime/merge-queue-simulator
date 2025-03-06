# frozen_string_literal: true

class Integer
  def seconds = self
  def minutes = seconds * 60
  def minute = minutes
  def hours = minutes * 60
  def hour = hours
  def days = hours * 24
  def day = days
end
