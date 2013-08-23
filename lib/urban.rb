require 'open-uri'
require 'nokogiri'
require 'cgi'

class UrbanDictionary
  include Cinch::Plugin

  match /urban (.+)/
  def lookup(word)
    url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}"
  
  	if word.split.last == 'url'
  		url[0..-5]	
  	else
    	CGI.unescape_html Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/, ' ') rescue nil
  	end
  end

  def execute(m, word)
    m.reply(lookup(word) || "No results found", true)
  end
end
