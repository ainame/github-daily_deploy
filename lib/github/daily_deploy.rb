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
      Dir.chdir(root_dir) do
        # see: https://github.com/blog/1270-easier-builds-and-deployments-using-git-over-https-and-oauth
        run("git clone https://#{ENV['GITHUB_ACCESS_TOKEN']}:x-oauth-basic@github.com/#{repository}.git")
      end
    end

    def push_release_branch(deploy_branch)
      Dir.chdir(root_dir) do
        Dir.chdir(repository.split('/')[1]) do
          run("git checkout master")
          run("git fetch origin")
          run("git checkout -b #{@release_branch} origin/#{deploy_branch}")
          run("git merge origin/master")
          run("git push origin #{@release_branch}")
        end
      end
    end

    def create_pull_request(deploy_branch:, title: nil)
      pull_request_title =
        title ? "#{title} - #{pull_request_title_timpstamp}" : default_pull_request_title
      client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      client.create_pull_request(@repository, deploy_branch, @release_branch, pull_request_title, pull_request_body)
    end

    def default_pull_request_title
      "Today's release - #{pull_request_title_timpstamp}"
    end

    def pull_request_title_timpstamp
      "#{@now.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    def pull_request_body
      "TODO"
    end

    def run(command)
      logger.info("$ " + command)
      system(command)
    end
  end
end
