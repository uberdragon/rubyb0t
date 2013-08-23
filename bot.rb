require 'cinch'
require 'sinatra'

Dir[File.dirname(__FILE__) + '/lib/**/*.rb'].each {|file| require file}

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.dal.net"
    c.nick   = "UberB0t"
    c.channels = ["#UberB0t"]
    c.plugins.plugins = [Admin, UrbanDictionary, Demo, Github, Cinch::Plugins::PluginManagement, Mobes, Wiki]
  end

  on :connect do
    user = Cinch::User.new 'NickServ', bot
    user.send "identify l3tm31n"
    #user.send "identify #{ENV['BOT_PASSWORD']}"
  end
end

Thread.new do
  bot.start
end

post '/announce' do
  bot.channels[0].msg params[:message]
end

File.open('tmp/irc_bot.pid', 'w') {|file| file << Process.pid }
