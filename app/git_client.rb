# frozen_string_literal: true

require 'git'

class GitClient
  GIT_FOLDER = File.join(File.dirname(__FILE__), '..', 'tmp')

  def initialize
    @client = init_repo!
    @mutex = Mutex.new

    client.commit('Initial commit', allow_empty: true)
  end

  def create_branch(branch_name, start_point: 'main')
    safely do
      client.checkout(branch_name, new_branch: true, start_point:)
    end
  end

  def create_commit(branch_name)
    safely do
      client.checkout(branch_name)
      client.commit("Done some work #{Random.rand(9999)}", allow_empty: true)
    end
  end

  def rebase_main(branch_name, **) = rebase(branch_name, onto: 'main', **)

  def rebase(branch_name, onto:, **opts)
    options = opts.keys.map { "--#{it.to_s.gsub('_', '-')}" }.join(' ')

    safely do
      client.checkout(branch_name)
      `pushd #{GIT_FOLDER}; git rebase #{options} #{onto}; popd`
    end
    client.checkout('main')
  end

  def merge(branch_name, onto: 'main')
    safely do
      client.checkout(onto)
      client.merge(branch_name, "Merging #{branch_name}", no_ff: true)
      delete_branch(branch_name) if onto == 'main'
    end
  end

  def delete_branch(branch_name)
    client.branch(branch_name).delete
  end

  def sha(branch_name)
    safely do
      client.checkout(branch_name)
      client.object('HEAD').sha
    end
  end

  def commit_message(sha)
    client.gcommit(sha).message
  end

  def parents(sha)
    client.gcommit(sha).log.map(&:sha) - [sha]
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

  attr_reader :client, :mutex
end
