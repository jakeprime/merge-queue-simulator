# frozen_string_literal: true

require 'io/console'

class Printer
  def initialize(circle, tail: false, show_commands: false)
    $stdout.sync = true

    @circle = circle
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

    lines = []
    lines += reversed_output(with_circle_statuses(output)).lines
    lines << ''
    lines += commands if show_commands
    lines << ''
    lines << statuses.last
    lines << ''

    puts(lines.compact.map(&:strip).map { "\r#{it}\n" })
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
    end.join
  end

  def with_circle_statuses(output)
    output.lines.map do |line|
      sha = line.scan(/[a-f0-9]{7}/)[0]
      next line unless sha

      "#{line.strip} #{circle_status(sha)}\n"
    end.join
  end

  def circle_status(sha)
    status = @circle.status(sha)

    color = {
      Circle::SUCCESS => :green,
      Circle::FAILURE => :red,
      Circle::IN_PROGRESS => :yellow,
    }[status]

    return status unless color

    status.to_s.send(color)
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
