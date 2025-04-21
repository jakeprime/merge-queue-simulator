# frozen_string_literal: true

module Accessors
  module_function

  def git = @git ||= GitClient.instance
  def circle = @circle ||= Circle.instance
  def printer = @printer ||= Printer.instance
end
