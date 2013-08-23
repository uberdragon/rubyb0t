class Admin
  include Cinch::Plugin

  match /join (.+)/, method: :join
  match /part(?: (.+))?/, method: :part
  match /op (.+)/, method: :op
  match /deop (.+)/, method: :deop
  match /kick (.+)/, method: :kick
  match /voice (.+)/, method: :voice
  match /devoice (.+)/, method: :devoice

  timer 300, method: :nick_check

  def initialize(*args)
    super

    @admins = ["lledet","Uber|Dragon","UberDragon"]
  end

  def check_user(user)
    user.refresh # be sure to refresh the data, or someone could steal the nick
    @admins.include?(user.nick)
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

  def nick_check
    unless @bot.nick == "RubyB0t"
      puts 'Fixing nick.'
      @bot.nick = "RubyB0t"
    end
  end
end
