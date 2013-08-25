require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class Google
  include Cinch::Plugin
  match /google (.+)/

  def search(query)
    url = "http://www.google.com/search?q=#{CGI.escape(query)}"

    if query.split.last == 'url'
      url[0..-5]
    else
      page = Nokogiri::HTML(open(url))
      title = page.at("h3.r").text
      desc = page.at("span.st").text
      link = page.at("h3.r").at('a')[:href].gsub('/url?q=','').split('&')[0]

      CGI.unescape_html "#{title} - #{desc} (#{link})"
    end
  rescue
    "No results found"
  end

  def execute(m, query)
    m.reply(search(query),true)
  end
end
