require 'cinch'
require 'sinatra'
require 'sinatra/contrib/all'
require 'rubygems'

set :public_folder, Proc.new { File.join(root, "web/assets") }
set :views, Proc.new { File.join(root, "web/templates") }

class WebHooks

  include Cinch::Plugin

	def self.announce message
		$bot.channels.each do |channel|
			channel.msg message
		end
		message
	end

end


# Listen to sinatra URLs

# This needs to be protected and probably moved into the /cmd area
# Currently allows anyone to send a /announce?message=<message here> which will
# /amsg all channels the bot is in with the message received.
get '/announce' do
	WebHooks.announce params[:message]
end

# Protected behind password area; this should give all kinds of stats the bot has collected
# such as ability to get bot feed back from triggers that store information; ie: !seen !top10 etc
get '/stats' do
	erb :stats
end

# Perhaps some data about the channels bot is in with ability
# to select a specific channel.  Channel relay to web, IRC @op commands, nick list etc accessible
get '/channels' do
	erb :channels
end

# Specific Channel Management and Control
get '/channel/:channel' do

end

# Intended to be an API to any command the bot can do based on permissions.
# should accept commands via POST in JSON format
get '/cmd' do

end

# Bot's index page - could show general stats for the public and then contain
# a login area to be able to control the bot and use it to channel spy etc
get '/' do
	erb :index, :locals => {:botname => $bot.nick}
end
