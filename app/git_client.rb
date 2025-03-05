# frozen_string_literal: true

require 'git'

class GitClient
  GIT_FOLDER = File.join(File.dirname(__FILE__), '..', 'tmp')

  def initialize(printer:, rebase:)
    @rebase = rebase
    @printer = printer

    @client = init_repo!
    @mutex = Mutex.new

    client.commit('Initial commit', allow_empty: true)
  end

  def create_branch(branch_name)
    safely do
      client.checkout(branch_name, new_branch: true, start_point: 'main')
    end
  end

  def create_commit(branch_name)
    safely do
      client.checkout(branch_name)
      client.commit("Done some work #{Random.rand(9999)}", allow_empty: true)
    end
  end

  def rebase_main(branch_name)
    safely do
      if rebase
        printer.status = "Rebasing #{branch_name}"

        client.checkout(branch_name)
        system("cd #{GIT_FOLDER}")
        system('git rebase main')
      end
      client.checkout('main')
    end
  end

  def merge(branch_name)
    safely do
      client.merge(branch_name, "Merging #{branch_name}", no_ff: true)
      client.branch(branch_name).delete
    end
  end

  def sha(branch_name)
    safely do
      client.checkout(branch_name)
      client.object('HEAD').sha
    end
  end

  def teardown
    FileUtils.rm_rf(GIT_FOLDER)
  end

  private

  def init_repo!
    FileUtils.rm_rf(GIT_FOLDER)
    Git.init(GIT_FOLDER)
  end

  def safely
    mutex.synchronize do
      result = yield
      client.checkout('main')
      result
    end
  end

  attr_reader :client, :mutex, :rebase, :printer
end
