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

$admins = ["UberB0t","Uber|Dragon","UberDragon"]
$global_sops = ["Ubie"]
$global_aops = []
$global_voices = []
$global_akicks = []
$global_bans = []

$channels = {} # Initialize the hash
$channels['#DragonCave'] = {
  :owners => [] + $admins,
  :sops => [] + $global_sops,
  :aops => [] + $global_aops,
  :voices => [] + $global_voices,
  :akick_list => [] + $global_akicks,
  :ban_list => [] + $global_bans
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

def user_has_access?(user,channel,type) # type => :owner, :sop, :aop, :voice
  user.refresh

  if $channels.include?(channel)
    c = $channels[channel]
    case type
    when :owner
      c[:owners].include?(user.nick)
    when :sop
      c[:sops].include?(user.nick) || c[:owners].include?(user.nick)
    when :aop
      c[:aops].include?(user.nick) || c[:sops].include?(user.nick) || c[:owners].include?(user.nick)
    when :voice
      c[:voices].include?(user.nick) || c[:aops].include?(user.nick) || c[:sops].include?(user.nick) || c[:owners].include?(user.nick)
    end
  else
    case type
    when :owner
      $admins.include?(user.nick)
    when :sop
      $global_sops.include?(user.nick) || $admins.include?(user.nick)
    when :aop
      $global_aops.include?(user.nick) || $global_sops.include?(user.nick) || $admins.include?(user.nick)
    when :voice
      $global_voices.include?(user.nick) || $global_aops.include?(user.nick) || $global_sops.include?(user.nick) || $admins.include?(user.nick)
    end
  end
end

def user_is_admin?(user)
  user.refresh # be sure to refresh the data, or someone could steal the nick
  $admins.include?(user.nick)
end
