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
  :bot_admins => ["UberB0t","Uber|Dragon","UberDragon"],
  :global_sops => ["Ubie"],
  :global_aops => [],
  :global_voices => [],
  :global_akicks => [],
  :global_bans => []
}

$global_admins = $settings[:bot_admins]
$global_sops = $settings[:global_sops]
$global_aops = $settings[:global_aops]
$global_voices = $settings[:global_voices]
$global_akicks = $settings[:global_akicks]
$global_bans = $settings[:global_bans]

bot = Cinch::Bot.new do

  configure do |c|
    c.server = $settings[:server]
    c.reconnect = true
    c.delay_joins = 10
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

def user_is_admin?(user)
  user.refresh # be sure to refresh the data, or someone could steal the nick
  $global_admins.include?(user.nick)
end
