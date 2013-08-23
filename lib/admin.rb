class Admin
  include Cinch::Plugin

  match /join (.+)/, method: :join
  match /part(?: (.+))?/, method: :part
  match /chan_op (.+)/, method: :channel_op
  match /op (.+)/, method: :op
  match /deop (.+)/, method: :deop
  match /kick (.+)/, method: :kick
  match /voice (.+)/, method: :voice
  match /devoice (.+)/, method: :devoice
  match /nick (.+)/, method: :nick_change
  match /nick_check (.+)/, method: :nick_check

  timer 300, method: :nick_check

  def initialize(*args)
    super

    @admins = ["UberB0t","Uber|Dragon","UberDragon"]
    @chanserv = Cinch::User.new 'ChanServ@services.dal.net', bot
    @nickserv = Cinch::User.new 'nickserv@services.dal.net', bot
    @memoserv = Cinch::User.new 'memoserv@services.dal.net', bot

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

  def channel_op(m, command) # channel then nickname
    return unless check_user(m.user)
    @chanserv.send "op #{command}"
  end

  def op(m, nick)
    return unless check_user(m.user)
    m.channel.op(nick)
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

  def auto_ident
    @nickserv.send = "identify l3tm31n"
  end

  def nick_check
    unless @bot.nick == "rubyb0t"
      puts 'Fixing nick.'
      @bot.nick = "rubyb0t"
      @nickserv.send = "identify l3tm31n"
    end
  end
end
