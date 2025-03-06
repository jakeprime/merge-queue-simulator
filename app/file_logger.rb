# frozen_string_literal: true

class FileLogger
  def self.log_file
    @file_path ||= File.join(File.dirname(__FILE__), '..', 'log').tap do |log_file|
      File.open(log_file, 'w') {}
    end
  end

  def self.log(msg)
    File.open(log_file, 'a') { it.puts msg }
  end
end
