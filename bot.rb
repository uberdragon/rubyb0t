require 'cinch'
require 'sinatra'
require "cinch/plugins/identify"

Dir[File.dirname(__FILE__) + '/lib/**/*.rb'].each {|file| require file}



bot = Cinch::Bot.new do

  configure do |c|
    c.server = "irc.dal.net"
    c.nick   = "rubyb0t"
    c.user = "rubyb0t"
    c.channels = ["#DragonCave","#Uber|Dragon"]
    c.plugins.plugins = [
      Admin,
      UrbanDictionary,
      Demo,
      Github,
      Cinch::Plugins::PluginManagement,
      Mobes,
      Wiki,
      Cinch::Plugins::Identify
    ]
    c.plugins.options[Cinch::Plugins::Identify] = {
      :username => "rubyb0t",
      :password => "l3tm31n",
      :type => :dalnet
    }

  end



  on :connect do
    # run general commands on connect
  end
end

Thread.new do
  bot.start
end

get '/announce' do
  bot.channels[0].msg params[:message]

end

File.open('tmp/irc_bot.pid', 'w') {|file| file << Process.pid }
