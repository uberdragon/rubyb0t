require 'octokit'
require 'net/http'
require 'net/https'
require 'shorturl'

class Github
  include Cinch::Plugin

  match /issues (.+)/, method: :issues
  match /issues$/, method: :all_issues

  def initialize(*args)
    super
    token = ENV['GITHUB_TOKEN']
    @client = Octokit::Client.new(:oauth_token => token)
  end

  def issues(m, repo)

    gitio = URI.parse('http://git.io/').freeze
    params = {
      'url' => "https://github.com/searchinfluence/#{repo}"
    }
    res = Net::HTTP.post_form(gitio, params)

    begin
      issues = @client.list_issues("searchinfluence/#{repo}")
      link = @client.repo("searchinfluence/#{repo}")
      if issues.nil?
        m.reply "#{repo} has no open issues"
      else
        m.reply res['location']
        issues.each do |issue|
          m.reply issue[1]
          m.reply "#{issue.number} #{issue.title}"
        end
      end
    rescue Octokit::NotFound => e
      m.reply "#{repo} does not exist"
    end
  end

  def all_issues(m)
    repos = @client.organization_repositories 'searchinfluence'
    repos = repos.sort_by { |repo| repo.open_issues }
    repos.reverse!

    repos.each do |repo|
      unless repo.open_issues == 0
        m.reply "#{repo.name} has #{repo.open_issues} open issues"
      end
    end
  end

end
