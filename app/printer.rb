# frozen_string_literal: true

require 'io/console'

class Printer
  def initialize
    @line_count = 0
    @statuses = []

    start
  end

  def start
    return if printing?

    @printing = true

    Thread.new do
      while printing?
        print_output
        sleep(0.1)
      end
    end
  end

  def stop
    @printing = false
    print_output
  end

  def status=(message)
    # statuses << message
  end

  private

  attr_reader :line_count, :statuses

  def printing? = @printing

  def print_output
    output = `cd tmp && git log --oneline --decorate --graph --color=always --all && cd ..`
    # puts "\e[A\e[K" * line_count
    IO.console.clear_screen
    puts reversed_output(output)
    puts statuses.last || ''
    # puts statuses.join("\n") if statuses.any?

    # @line_count = output.lines.count + 2
  end

  def reversed_output(output)
    output.lines.reverse.map do |line|
      line
        .gsub('/', 'FORWARD_SLASH')
        .gsub('\\', 'BACK_SLASH')
        .gsub('BACK_SLASH', '/')
        .gsub('FORWARD_SLASH', '\\')
    end
  end
end
