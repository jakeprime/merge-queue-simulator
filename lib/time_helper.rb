# frozen_string_literal: true

class Integer
  def seconds = self
  def minutes = seconds * 60
  def hours = minutes * 60
end
