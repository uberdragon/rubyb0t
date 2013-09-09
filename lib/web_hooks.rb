require 'cinch'
require 'sinatra'

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

get '/announce' do
	WebHooks.announce params[:message]
end

get '/stats' do

"Displaying Stats"

end

get '/' do
	erb :index
end
