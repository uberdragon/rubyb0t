class Admin
  include Cinch::Plugin

  match /join (.+)/, method: :join
  match /j (.+)/, method: :join

  match /part(?: (.+))?/, method: :part
  match /p(?: (.+))?/, method: :part

  match /chan_op(?: (.+))?/, method: :channel_op
  match /op(?: (.+))?/, method: :op
  match /deop (.+)/, method: :deop
  match /kick (.+)/, method: :kick
  match /voice (.+)/, method: :voice
  match /v (.+)/, method: :voice

  match /devoice (.+)/, method: :devoice

  match /nick (.+)/, method: :nick_change
  match /nick_check/, method: :nick_check
  match /ident/, method: :ident

  #match "You're not channel operator", method: :self_op

  timer 60*30, method: :nick_check

  def initialize(*args)
    super

    @admins = ["UberB0t","Uber|Dragon","UberDragon"]

    case $settings[:network]
    when :dalnet
      @chanserv = Cinch::User.new 'ChanServ@services.dal.net', bot
      @nickserv = Cinch::User.new 'NickServ@services.dal.net', bot
      @memoserv = Cinch::User.new 'MemoServ@services.dal.net', bot
    else
      @chanserv = Cinch::User.new 'ChanServ', bot
      @nickserv = Cinch::User.new 'NickServ', bot
      @memoserv = Cinch::User.new 'MemoServ', bot
    end

  end

  def check_user(user)
    user.refresh # be sure to refresh the data, or someone could steal the nick
    @admins.include?(user.nick)
  end

  def nick_change(m, nick)
    return unless check_user(m.user)
    @bot.nick = nick
  end

  def join(m, channel)
    return unless check_user(m.user)
    Channel(channel).join
  end

  def part(m, channel)
    return unless check_user(m.user)
    channel ||= m.channel
    Channel(channel).part if channel
  end

  def channel_op(m, input) # channel then nickname
    return unless check_user(m.user)
    if !input.to_s.empty?
      options = input.split
      channel = options[0] if options.length > 1
      nick = options[1] if options.length > 1
      nick = options[0] if options.length == 1
    end
    channel = channel ||= m.channel
    nick = nick ||= @bot.nick
    @chanserv.send "op #{channel} #{nick}"
  end

  def op(m, input)
    return unless check_user(m.user)
    if !input.to_s.empty?
      options = input.split
      channel = options[0] if options.length > 1
      nick = options[1] if options.length > 1
      nick = options[0] if options.length == 1
    end
    channel ||= m.channel
    nick ||= m.user

    if bot_has_ops?(channel)
      Channel(channel).op(nick)
    else
      m.reply "Channel says I'm not an OP... attempting to fixing that anomaly... >:)"
      @chanserv.send "op #{m.channel} #{@bot.nick}"
      sleep(5)
      Channel(channel).op(nick)
    end

  end

  def deop(m, nick)
    return unless check_user(m.user)
    m.channel.deop(nick)
  end

  def kick(m, nick)
    return unless check_user(m.user) && nick != @bot.nick
    m.channel.kick(nick)
  end

  def voice(m, nick)
    return unless check_user(m.user)
    m.channel.voice(nick)
  end

  def devoice(m, nick)
    return unless check_user(m.user)
    m.channel.devoice(nick)
  end

  def ident(m)
    return unless check_user(m.user)    
    @nickserv.send "identify %s" % [$settings[:password]]
    m.reply "I have identified to nickserv!"
  end

  def nick_check
    unless @bot.nick == $settings[:nick]
      m.reply 'Fixing nick.'
      @bot.nick = $settings[:nick]
    end
  end

  def bot_has_ops?(channel,nick=@bot.nick)
    Channel(channel).opped? nick
  end
end
