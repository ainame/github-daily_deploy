require "github/daily_deploy/version"
require "octokit"

module Github
  class DailyDeploy
    attr_accessor :logger, :root_dir, :repository

    def initialize(root_dir:, repository:, logger: nil)
      self.logger = logger || ::Logger.new(STDOUT)
      @root_dir = File.expand_path(root_dir)
      @repository = repository
      @now = Time.now
      @release_branch = "release-#{@now.strftime("%Y%m%d%H%M%S")}"
      @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
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

    def is_cloned_repository
      Dir.chdir(root_dir) do
        begin
          Dir.chdir(repository.split('/')[1]) do
            run("git status")
          end
        rescue => e
        end
      end
    end

    def push_release_branch(deploy_branch)
      Dir.chdir(root_dir) do
        Dir.chdir(repository.split('/')[1]) do
          run("git checkout master")
          run("git fetch origin")
          run("git checkout -b #{@release_branch} origin/#{deploy_branch}")
          run("git merge origin/master --no-edit")
          run("git push origin #{@release_branch}")
        end
      end
    end

    def create(deploy_branch:, title: nil)
      response = create_pull_request(deploy_branch, title)
      summarize_pull_request(response[:number])
    end

    def create_pull_request(deploy_branch, title = nil)
      pull_request_title =
        title ? "#{title} - #{pull_request_title_timpstamp}" : default_pull_request_title
      @client.create_pull_request(@repository, deploy_branch, @release_branch, pull_request_title, default_pull_request_body)
    end

    def summarize_pull_request(number)
      merged_commits = @client.pull_request_commits(@repository, number)
      merged_pull_requests = extract_merged_pull_requests(merged_commits)
      new_body = summarize_pull_request_body(merged_pull_requests)
      @client.update_pull_request(@repository, number, body: new_body)
    end

    def extract_merged_pull_requests(merged_commits)
      merged_commits
        .map { |com| com[:commit][:message] }
        .map { |message| match = message.match(/\AMerge pull request #(\d*).*$/); match ? match.captures[0] : nil }
        .compact
        .map { |number| @client.pull_request(@repository, number) }
    end

    def summarize_pull_request_body(merged_pull_requests)
      merged_pull_requests
        .map { |pr| "* #{pr[:title]} ##{pr[:number]}" }
        .join("\n")
    end

    def default_pull_request_title
      "Today's release - #{pull_request_title_timpstamp}"
    end

    def pull_request_title_timpstamp
      "#{@now.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    def default_pull_request_body
      "TODO"
    end

    def run(command)
      logger.info("$ " + command)
      system(command)
    end
  end
end
