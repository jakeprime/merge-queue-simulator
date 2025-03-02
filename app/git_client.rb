# frozen_string_literal: true

require 'git'

class GitClient
  GIT_FOLDER = File.join(File.dirname(__FILE__), '..', 'tmp')

  def initialize
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

  def merge(branch_name)
    safely do
      client.checkout('main')
      client.merge(branch_name, "Merging #{branch_name}", no_ff: true)
      client.branch(branch_name).delete
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
      yield
      client.checkout('main')
    end
  end

  attr_reader :client, :mutex
end
