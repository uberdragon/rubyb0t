require 'cinch'

class Seen

  class SeenStruct < Struct.new(:who, :where, :what, :type, :time, :operator)
    def last_seen
      case type
      when 'msg'
        "[#{time.asctime}] #{who} was seen in #{where} saying, \"#{what}\""
      when 'action'
        "[#{time.asctime}] #{who} was seen in #{where} using an action, \"#{what}\""
      when 'quit'
        "[#{time.asctime}] #{who} was seen quiting IRC with message, \"#{what}\""
      when 'join'
        "[#{time.asctime}] #{who} was seen joining #{where}"
      when 'part'
        "[#{time.asctime}] #{who} was seen leaving #{where} with message, \"#{what}\""
      when 'op'
        "[#{time.asctime}] #{who} was seen getting OP in #{where} by #{operator}"
      when 'deop'
        "[#{time.asctime}] #{who} was seen losing OP in #{where} by #{operator}"
      when 'kick'
        "[#{time.asctime}] #{who} was seen getting kicked out of #{where} by #{operator} with message, \"#{what}\""
      when 'ban'
        "[#{time.asctime}] #{who} was banned in #{where} by #{operator} (#{what})"
      when 'unban'
        "[#{time.asctime}] #{who} was unbanned in #{where} by #{operator} (#{what})"
      when 'voice'
        "[#{time.asctime}] #{who} was voiced in #{where} by #{operator}"
      when 'devoice'
        "[#{time.asctime}] #{who} was devoiced in #{where} by #{operator}"
      end
    end
  end

  include Cinch::Plugin

  listen_to :connect, method: :listen_connect
  listen_to :disconnect, method: :listen_disconnect

  listen_to :channel, method: :listen_channel
  listen_to :quit, method: :listen_quit
  listen_to :join, method: :listen_join
  listen_to :part, method: :listen_part
  listen_to :op, method: :listen_op
  listen_to :deop, method: :listen_deop
  listen_to :voice, method: :listen_voice
  listen_to :devoice, method: :listen_devoice
  listen_to :kick, method: :listen_kick
  listen_to :ban, method: :listen_ban
  listen_to :unban, method: :listen_unban


  match /seen (.+)/, method: :execute

  def initialize(*args)
    super
    @users = {}
  end

  def listen_connect(m)
    @users = ObjectStash.load 'tmp/seen-users.stash'
  end

  def listen_disconnect(m)
    ObjectStash.store @users, './tmp/seen-users.stash'
  end

  def listen_channel(m)
    return if m.user == @bot.nick
    if m.message.to_s.gsub("\u0001","").split[0] == "ACTION"
      type = 'action'
      message = m.message.to_s.gsub("\u0001","").split[1..-1].join(" ")
    else
      message = m.message
      type = 'msg'
    end
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, m.channel.name, message, type, Time.now)
  end

  def listen_op(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'op', Time.now,m.user)
  end

  def listen_deop(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'deop', Time.now, m.user)
  end

  def listen_voice(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'voice', Time.now, m.user)
  end

  def listen_devoice(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'devoice', Time.now, m.user)
  end

  def listen_kick(m)
    return if m.user.nick == @bot.nick
    @users[m.params[1].downcase] = SeenStruct.new(m.params[1], m.channel.name, m.message, 'kick', Time.now, m.user.nick)
  end

  def listen_ban(m, mask)
    return if m.user.nick == @bot.nick
    nick = mask.to_s.split("!")[0]
    @users[nick.downcase] = SeenStruct.new(nick, m.channel.name, mask, 'ban', Time.now, m.user.nick)
  end

  def listen_unban(m, mask)
    return if m.user.nick == @bot.nick
    nick = mask.to_s.split("!")[0]
    @users[nick.downcase] = SeenStruct.new(nick, m.channel.name, mask, 'unban', Time.now, m.user.nick)
  end

  def listen_quit(m)
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, :none, m.message, 'quit', Time.now)
  end

  def listen_join(m)
    return if m.user.nick == @bot.nick
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, m.channel.name, :none, 'join', Time.now)
  end

  def listen_part(m)
    return if m.user.nick == @bot.nick
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, m.channel.name, m.message, 'part', Time.now)
  end

  def execute(m, nick)
    if nick.downcase == @bot.nick.downcase
      m.reply "That's me!"
    elsif nick.downcase == m.user.nick.downcase
      m.reply "That's you!"
    elsif @users.key?(nick.downcase)
      m.reply @users[nick.downcase].last_seen
    else
      m.reply "I haven't seen #{nick}"
    end
  end
end
