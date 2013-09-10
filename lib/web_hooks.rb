require 'cinch'
require 'sinatra'
require 'rubygems'

set :public_folder, Proc.new { File.join(root, "static") }

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
	erb "wtf"
end

get '/' do
	erb "showing index y0"
end
