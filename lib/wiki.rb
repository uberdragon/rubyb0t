require 'open-uri'
require 'nokogiri'
require 'cgi'

class Wiki

	include Cinch::Plugin

	match /wiki (.+)/

	def lookup(phrase) 
		safe_phrase = phrase.gsub(" ", "_").capitalize
    url = "http://en.wikipedia.org/wiki/#{CGI.escape(safe_phrase)}"

  	if phrase.split.last == 'url'
  		url[0..-5]	
  	else
			CGI.unescape_html Nokogiri::HTML(open(url)).at("div.mw-content-ltr p + p").text.gsub(/\s+/, ' ') rescue nil
		end
	end

	def execute(m, phrase)
		m.reply(lookup(phrase) || "No results found", true)
	end

end
