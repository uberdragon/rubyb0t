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
  :auto_channels => ["#DragonCave","#Uber|Dragon"],
  :github_feed => "https://github.com/searchinfluence/"
}

bot = Cinch::Bot.new do

  configure do |c|
    c.server = $settings[:server]
    c.nick   = $settings[:nick]
    c.user = $settings[:user]
    c.channels = $settings[:auto_channels]
    c.plugins.plugins = [
      Admin,
      UrbanDictionary,
      Demo,
      Github,
      Cinch::Plugins::PluginManagement,
      Wiki,
      Cinch::Plugins::Identify
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

  on :message, /hello(.+)/ do |m|
    m.reply "Hello, #{m.user.nick}"
  end

  on :no_channel_op do |m|
    m.reply "Sorry can't help you I couldn't obtain OP here."
  end
end

Thread.new do
  bot.start
end

get '/announce' do
  bot.channels[0].msg params[:message]

end

File.open('tmp/irc_bot.pid', 'w') {|file| file << Process.pid }
