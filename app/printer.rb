# frozen_string_literal: true

require 'io/console'

class Printer
  def initialize(tail: false, show_commands: false)
    @statuses = []
    @show_commands = show_commands

    print_output

    self.tail if tail
  end

  def tail
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
    statuses << message
  end

  def print_output
    output = `cd tmp && git log --oneline --decorate --graph --color=always --all && cd ..`

    IO.console.clear_screen
    puts reversed_output(output)
    puts ''
    puts commands if show_commands
    puts ''
    puts statuses.last
  end

  private

  attr_reader :statuses, :show_commands

  def printing? = @printing

  def reversed_output(output)
    output.lines.reverse.map do |line|
      line
        .gsub('/', 'FORWARD_SLASH')
        .gsub('\\', 'BACK_SLASH')
        .gsub('BACK_SLASH', '/')
        .gsub('FORWARD_SLASH', '\\')
    end
  end

  def commands
    [
      'Perform an action on a random branch',
      '',
      'B: Create a new branch',
      'C: Create a new commit',
      'M: Merge a branch',
      'Q: Quit',
    ]
  end
end
