require 'cinch'
require 'sinatra'
require "cinch/plugins/identify"

Dir[File.dirname(__FILE__) + '/lib/**/*.rb'].each {|file| require file}

$settings = {
  :nick => "rubyb0t",
  :user => "rubyb0t",
  :password => "l3tm31n",
  :network => :dalnet,
  :server => "irc.dal.net",
  :auto_channels => ["#DragonCave","#Uber|Dragon","#html"],
  :github_feed => "https://github.com/searchinfluence/"
}

bot = Cinch::Bot.new do

  configure do |c|
    c.server = $settings[:server]
    c.nick   = $settings[:nick]
    c.user = $settings[:user]
    c.channels = $settings[:auto_channels]
    c.plugins.plugins = [
      Cinch::Plugins::Identify,
      Cinch::Plugins::PluginManagement,
      Admin,
      Demo,
      DiceRoll,
      Github,
      Google,
      Seen,
      Wiki,
      UrbanDictionary
    ]
    c.plugins.options[Cinch::Plugins::Identify] = {
      :username => $settings[:nick],
      :password => $settings[:password],
      :type => $settings[:network]
    }

  end

  on :connect do
    # run general commands on connect
  end

  on :disconnect do
    Thread.new do
      bot.start
    end
  end

  on :message, /hello(.+)/ do |m|
    m.reply "Hello, #{m.user.nick}"
  end


  on 482 do |m|
    m.reply "Sad, I don't have ops here."
  end
end

bot.loggers << Cinch::Logger::FormattedLogger.new(File.open("./log/log.log", "a"))
bot.loggers.level = :debug
bot.loggers.first.level = :log

Thread.new do
  bot.start
end

get '/announce' do
  bot.channels[0].msg params[:message]
end

File.open('tmp/irc_bot.pid', 'w') {|file| file << Process.pid }
