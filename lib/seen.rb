require 'open-uri'
require 'nokogiri'
require 'cgi'

class Math_Helper

	include Cinch::Plugin

	match /([-+]?[0-9]*\.?[0-9]+[\/\+\-\*])+([-+]?[0-9]*\.?[0-9]+)/

	def execute(m, data)
		m.reply("Found some Math!" || "No translation found", true)
	end

end
