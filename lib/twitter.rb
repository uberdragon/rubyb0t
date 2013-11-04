require 'open-uri'
require 'nokogiri'
require 'cgi'

class Twitter
  include Cinch::Plugin

  match %r{(^https://twitter.com/.*/status/\d+$)}, use_prefix: false, method: :execute
  match /twitter (.+)/, method: :fetch_tweet

  def fetch_tweet m, nickname
    if nickname.split.pop.to_i > 0
      num = nickname.split.pop.to_i
      nickname = nickname.split[0...-1].join(" ")
    end
    if num.to_i > 0
      s = num - 1
    else
      s = 0
    end

    url = "https://twitter.com/#{nickname}"
    doc = Nokogiri::HTML(open(url).read)

    if tweet = doc.css('.tweet-text')
      begin
        m.reply tweet[s].text
      rescue 
        m.reply tweet.last.text
      end
    else
      m.reply "ERROR: Couldn't read tweet."
    end
  end

  def execute m, url
    doc = Nokogiri::HTML(open(url).read)

    if tweet = doc.css('.tweet-text')
      m.reply tweet.first.text
    else
      m.reply "ERROR: Couldn't read tweet."
    end
  end
end
