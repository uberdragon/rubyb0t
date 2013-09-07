require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class News
  include Cinch::Plugin
  match /news (.+)/

  def search(query)
    if query.split.last == 'url'
      query = query.split[0...-1].join(" ")
      return "http://www.google.com/search?hl=en&gl=us&tbm=nws&authuser=0&q=#{CGI.escape(query)}"
    else
      if query.split.pop.to_i > 0
        num = query.split.pop.to_i
        query = query.split[0...-1].join(" ")
      end
      url = "http://www.google.com/search?hl=en&gl=us&tbm=nws&authuser=0&q=#{CGI.escape(query)}"
      if num.to_i > 0
        s = num - 1
      else
        s = 0
      end

      page = Nokogiri::HTML(open(url))

      log(page.inspect, :debug)
      
      desc = link = ''

      title = page.css("h3.r")[s].text
      source = page.css("div.slp")[s].text
      desc = page.css("div.st")[s].text
      link = page.css("h3.r")[s].at('a')[:href].gsub('/url?q=','').split('&')[0]

      CGI.unescape_html "[#{source}] #{title} - #{desc} (#{link})"

    end

  rescue
    "No results found"
  end

  def execute(m, query)
    m.reply(search(query),true)
  end
end
