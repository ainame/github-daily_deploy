require "github/daily_deploy/version"

module Github
  class DailyDeploy
    def logger
      @logger
    end

    def logger=(logger)
      @logger = logger
    end

    def self.create_release_branch(root_dir:, deploy_branch:, logger: nil)
      self.logger = logger || ::Logger.new(STDOUT)
      git = GitRepository.new(
        root_dir: root_dir,
        deploy_branch: deploy_branch,
        release_branch: "release-#{Time.now.strftime("%Y%m%d%H%M%S")}"
      )
      git.push_release_branch
    end

    class GitRepository
      attr_accessor :root_dir, :deploy_branch, :release_branch

      def initialize(root_dir:, deploy_branch:)
        @root_dir = root_dir
        @deploy_branch = deploy_branch
        @release_branch = "release-#{Time.now.strftime("%Y%m%d%H%M%S")}"
      end

      def push_release_branch
        unless run("cd #{root_dir}")
          return
        end

        unless run("git checkout master")
          puts("can't checkout master branch")
          return
        end

        unless run("git fetch origin")
          return
        end

        unless run("git checkout -b #{release_branch} origin/#{deploy_branch}")
          return
        end

        unless run("git merge origin/master")
          return
        end

        unless run("git push origin #{release_branch}")
          return
        end

        release_branch
      end

      def run(command)
        DailyDeploy.logger.info("$ " + command)
        system(command)
      end
    end

    class GithubPullRequest
      def intialize()
      end
    end
  end
end
