# frozen_string_literal: true

require 'io/console'

class Printer
  include Accessors

  class << self
    def init(...) = @instance ||= new(...)

    attr_reader :instance
  end

  def initialize(config: Config.default)
    $stdout.sync = true

    @config = config
    @statuses = []

    tail if auto?
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

    lines = []
    lines += reversed_output(with_circle_statuses(output)).lines
    unless silent
      lines << ''
      lines += commands if show_commands?
      lines << ''
      lines += (persist? ? statuses : [statuses.last])
      lines << ''
    end

    IO.console.clear_screen
    puts(lines.compact.map(&:strip).map { "#{it}\r" })
  end

  private

  delegate :auto, :persist_log, :silent, to: :config

  attr_reader :config, :statuses, :show_commands

  def printing? = @printing
  def persist? = persist_log
  def auto? = auto
  def show_commands? = !auto?

  def reversed_output(output)
    output.lines.reverse.map do |line|
      line
        .gsub('/', 'FORWARDSLASH')
        .gsub('\\', 'BACKSLASH')
        .gsub('‾', 'OVERLINE')
        .gsub('_', 'UNDERSCORE')
        .gsub('BACKSLASH', '/')
        .gsub('FORWARDSLASH', '\\')
        .gsub('OVERLINE', '_')
        .gsub('UNDERSCORE', '‾')
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
    {
      Circle::SUCCESS => '🟢',
      Circle::FAILURE => '🔴',
      Circle::IN_PROGRESS => '🟡',
    }[circle.status(sha)]
  end

  def circle_state
    [
      'Circle state:',
      "In progress: #{circle.in_progress}",
      "Pass: #{circle.successes}",
      "Fail: #{circle.failures}",
    ]
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
