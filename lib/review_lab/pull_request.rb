# frozen_string_literal: true

require 'active_model'
require './lib/review_lab/logger'
require './lib/review_lab/utils'

class ReviewLab
  class PullRequest
    include ActiveModel::Model
    include Logger
    include Utils
    attr_accessor :content
    attr_writer :logger

    def update(directory)
      logger.info('Pull request already exists.')
      return unless changed?(directory)
      logger.info('Pull request changed, updating...')
      fetch_and_reset(directory)
    end

    def clone(directory)
      Dir.mkdir(directory)
      Dir.chdir(directory) do
        capture2e_with_logs(clone_command)
      end
    end

    def number
      content.number
    end

    def user_login
      content.head.user.login
    end

    def branch
      content.head.ref
    end

    def full_repository_name
      content.head.repo.full_name
    end

    private

    def fetch_and_reset(directory)
      Dir.chdir(File.join(directory, project_name)) do
        capture2e_with_logs('git fetch --all')
        capture2e_with_logs("git reset origin/#{branch} --hard")
      end
      logger.info("Successfully updated branch to #{head_sha}")
    end

    def changed?(directory)
      return true if head_sha != cloned_sha(directory)
      logger.info('Pull request did not change, continue...')
      false
    end

    def project_name
      content.head.repo.name
    end

    def cloned_sha(directory)
      Dir.chdir(File.join(directory, project_name)) do
        capture2e_with_logs('git rev-parse HEAD')
      end
    end

    def head_sha
      content.head.sha
    end

    def fork_url
      content.head.repo.clone_url
    end

    def clone_command
      "git clone -b #{branch} --single-branch #{fork_url}"
    end
  end
end