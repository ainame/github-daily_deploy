require "github/daily_deploy/version"
require "octokit"

module Github
  class DailyDeploy
    attr_accessor :root_dir, :repository

    def logger
      @logger
    end

    def logger=(logger)
      @logger = logger
    end

    def initialize(root_dir:, repository:, logger: nil)
      self.logger = logger || ::Logger.new(STDOUT)
      @root_dir = File.expand_path(root_dir)
      @repository = repository
      @now = Time.now
      @release_branch = "release-#{@now.strftime("%Y%m%d%H%M%S")}"
    end

    def create_release_branch(deploy_branch)
      return @release_branch if push_release_branch(deploy_branch)
    end

    def checkout_repository
      run("cd #{root_dir}")
      run("git clone https://github.com/#{repository}.git")
      run("cd #{repository.split('/')[1]}")
    end

    def push_release_branch(deploy_branch)
      run("cd #{root_dir}")
      run("git checkout master")
      run("git fetch origin")
      run("git checkout -b #{@release_branch} origin/#{deploy_branch}")
      run("git merge origin/master")
      run("git push origin #{@release_branch}")
    end

    def create_pull_request(deploy_branch)
      client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      client.create_pull_request(@repository, deploy_branch, @release_branch, pull_request_title, pull_request_body)
    end

    def pull_request_title
      "Today's release - #{@now.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    def pull_request_body
      "TODO"
    end

    def run(command)
      logger.info("$ " + command)
      # system(command)
    end
  end
end
