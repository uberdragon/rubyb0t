require 'cinch'

class Seen

  class SeenStruct < Struct.new(:who, :where, :what, :type, :time, :operator)
    def last_seen
      now = Time.now
      total_seconds = now.to_i - time.to_i
      time_since = "- #{Utils.seconds_to_string(total_seconds)} ago. [#{Time.at(time).asctime}]"
      case type
      when 'nick'
        "%s was seen changing nick to %s %s" % [who,what,time_since]
      when 'msg'
        "%s was seen in %s saying, \"%s\" %s" % [who,where,what,time_since]
      when 'action'
        "%s was seen in %s using an action, \"%s\" %s" % [who,where,what,time_since]
      when 'quit'
        "%s was seen quiting IRC with message, \"%s\" %s" % [who,what,time_since]
      when 'join'
        "%s was seen joining %s %s" % [who,where,time_since]
      when 'part'
        "%s was seen leaving %s with message, \"%s\" %s" % [who,where,what,time_since]
      when 'op'
        "%s was seen getting OP in %s by %s %s" % [who,where,operator,time_since]
      when 'deop'
        "%s was seen losing OP in %s by %s %s" % [who,where,operator,time_since]
      when 'kick'
        "%s was seen getting kicked out of %s by %s with message, \"%s\" %s" % [who,where,operator,what,time_since]
      when 'ban'
        "%s was banned in %s by #{operator} (%s) %s" % [who,where,operator,what,time_since]
      when 'unban'
        "%s was unbanned in %s by %s (%s) %s" % [who,where,operator,what,time_since]
      when 'voice'
        "%s was voiced in %s by %s %s" % [who,where,operator,time_since]
      when 'devoice'
        "%s was devoiced in %s by %s %s" % [who,where,operator,time_since]
      when 'away'
        "%s went away with message, \"%s\" %s" % [who,what,time_since]
      when 'unaway'
        "%s came back from away %s" % [who,time_since]
      end
    end
  end

  include Cinch::Plugin

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
  listen_to :away, method: :listen_away
  listen_to :unaway, method: :listen_unaway
  listen_to :nick, method: :listen_nickchange

  match /seen (.+)/, method: :execute

  timer 600, method: :backup_data!

  def initialize(*args)
    super
    @users = ObjectStash.load './tmp/seen-users.stash' || {}
    log("===== Loading !seen Data from Disk into Memory =====", :info)
  end

  def listen_disconnect(m)
    backup_data!
  end

  def listen_nickchange(m)
    return if m.user.last_nick == @bot.nick
    return if m.user.nick == @bot.nick
    @users[m.user.last_nick.downcase] = SeenStruct.new(m.user.last_nick, :none, m.user.nick, 'nick', Time.now.to_i)
  end

  def listen_away(m)
    return if m.user.nick == @bot.nick
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, :none, m.message, 'away', Time.now.to_i)
  end

  def listen_unaway(m)
    return if m.user.nick == @bot.nick
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, :none, :none, 'unaway', Time.now.to_i)
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
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, m.channel.name, message, type, Time.now.to_i)
  end

  def listen_op(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'op', Time.now.to_i,m.user)
  end

  def listen_deop(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'deop', Time.now.to_i, m.user)
  end

  def listen_voice(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'voice', Time.now.to_i, m.user)
  end

  def listen_devoice(m, nick)
    return if m.user.nick == @bot.nick
    @users[nick.nick.downcase] = SeenStruct.new(nick.nick, m.channel.name, :none, 'devoice', Time.now.to_i, m.user)
  end

  def listen_kick(m)
    return if m.user.nick == @bot.nick
    @users[m.params[1].downcase] = SeenStruct.new(m.params[1], m.channel.name, m.message, 'kick', Time.now.to_i, m.user.nick)
  end

  def listen_ban(m, mask)
    return if m.user.nick == @bot.nick
    nick = mask.to_s.split("!")[0]
    @users[nick.downcase] = SeenStruct.new(nick, m.channel.name, mask, 'ban', Time.now.to_i, m.user.nick)
  end

  def listen_unban(m, mask)
    return if m.user.nick == @bot.nick
    nick = mask.to_s.split("!")[0]
    @users[nick.downcase] = SeenStruct.new(nick, m.channel.name, mask, 'unban', Time.now.to_i, m.user.nick)
  end

  def listen_quit(m)
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, :none, m.message, 'quit', Time.now.to_i)
  end

  def listen_join(m)
    return if m.user.nick == @bot.nick
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, m.channel.name, :none, 'join', Time.now.to_i)
  end

  def listen_part(m)
    return if m.user.nick == @bot.nick
    @users[m.user.nick.downcase] = SeenStruct.new(m.user.nick, m.channel.name, m.message, 'part', Time.now.to_i)
  end

  def backup_data!
    log("===== Backing up !seen data from memory to disk =====", :info)
    log(@users.inspect, :debug)
    ObjectStash.store @users, './tmp/seen-users.stash'
  end

  def execute(m, nick)
    if nick.downcase == @bot.nick.downcase
      m.reply("That's me!",true)
    elsif nick.downcase == m.user.nick.downcase
      m.reply("That's you!",true)
    elsif @users.key?(nick.downcase)
      m.reply(@users[nick.downcase].last_seen,true)
    else
      m.reply("I haven't seen #{nick}",true)
    end
  end
end
