require 'open-uri'
require 'nokogiri'
require 'cgi'

class UrbanDictionary
  include Cinch::Plugin

  match /urban (.+)/
  def lookup(query)
    if query.split.last == 'url'
      query = query.split[0...-1].join(" ")
      return "http://www.urbandictionary.com/define.php?term=#{CGI.escape(query)}"
    else
      if query.split.pop.to_i > 0
        num = query.split.pop.to_i
        query = query.split[0...-1].join(" ")
      end
      url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(query)}"
      if num.to_i > 0
        s = num - 1
      else
        s = 0
      end
    	CGI.unescape_html Nokogiri::HTML(open(url)).css("div.definition")[s].text.gsub(/\s+/, ' ') rescue nil
  	end
  end

  def execute(m, word)
    m.reply(lookup(word) || "No results found", true)
  end
end
