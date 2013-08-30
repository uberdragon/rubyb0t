require 'cinch'

class Seen

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

  timer 600, method: :backup_data! # 10 minutes

  def initialize(*args)
    super
    @users = DataStash.load './tmp/seen-users.stash' || {}
    log("===== Loading !seen Data from Disk into Memory =====", :info)
    log(@users.inspect, :debug)
  end

  def listen_disconnect(m)
    backup_data!
  end

  def listen_nickchange(m)
    return if m.user.last_nick == @bot.nick
    return if m.user.nick == @bot.nick
    build_data(m.user.last_nick, :none, m.user.nick, 'nick', Time.now.to_i)
  end

  def listen_away(m)
    return if m.user.nick == @bot.nick
    build_data(m.user.nick, :none, m.message, 'away', Time.now.to_i)
  end

  def listen_unaway(m)
    return if m.user.nick == @bot.nick
    build_data(m.user.nick, :none, :none, 'unaway', Time.now.to_i)
  end

  def listen_channel(m)
    return if m.user.nick == @bot.nick
    if m.message.to_s.gsub("\u0001","").split[0] == "ACTION"
      type = 'action'
      message = m.message.to_s.gsub("\u0001","").split[1..-1].join(" ")
    else
      message = m.message
      type = 'msg'
    end
    build_data(m.user.nick, m.channel.name, message, type, Time.now.to_i)
  end

  def listen_op(m, nick)
    return if nick.nick == @bot.nick
    build_data(nick.nick, m.channel.name, :none, 'op', Time.now.to_i, m.user.nick)
  end

  def listen_deop(m, nick)
    return if nick.nick == @bot.nick
    build_data(nick.nick, m.channel.name, :none, 'deop', Time.now.to_i, m.user.nick)
  end

  def listen_voice(m, nick)
    return if nick.nick == @bot.nick
    build_data(nick.nick, m.channel.name, :none, 'voice', Time.now.to_i, m.user.nick)
  end

  def listen_devoice(m, nick)
    return if nick.nick == @bot.nick
    build_data(nick.nick, m.channel.name, :none, 'devoice', Time.now.to_i, m.user.nick)
  end

  def listen_kick(m)
    return if m.params[1] == @bot.nick
    build_data(m.params[1], m.channel.name, m.message, 'kick', Time.now.to_i, m.user.nick)
  end

  def listen_ban(m, mask)
    nick = mask.to_s.split("!")[0]
    return if nick == @bot.nick
    build_data(nick, m.channel.name, mask, 'ban', Time.now.to_i, m.user.nick)
  end

  def listen_unban(m, mask)
    nick = mask.to_s.split("!")[0]
    return if nick == @bot.nick
    build_data(nick, m.channel.name, mask, 'unban', Time.now.to_i, m.user.nick)
  end

  def listen_quit(m)
    build_data(m.user.nick, :none, m.message, 'quit', Time.now.to_i)
  end

  def listen_join(m)
    return if m.user.nick == @bot.nick
    build_data(m.user.nick, m.channel.name, :none, 'join', Time.now.to_i)
  end

  def listen_part(m)
    return if m.user.nick == @bot.nick
    build_data(m.user.nick, m.channel.name, m.message, 'part', Time.now.to_i)
  end

  def build_data who, where, what, type, time, operator=nil
    puts who.downcase.to_sym
    @users[who.downcase.to_sym] = {
      :who => who,
      :where => where,
      :what => Utils.strip(what),
      :type => type,
      :time => time.to_i,
      :operator => operator
    }
  end

  def seen_reply d
    now = Time.now
    total_seconds = now.to_i - d[:time]
    timestamp = "- #{Utils.seconds_to_string(total_seconds)} ago. [#{Time.at(d[:time]).asctime}]"

    case d[:type]
    when 'nick'
      "%s was seen changing nick to %s %s" % [d[:who],d[:what],timestamp]
    when 'msg'
      "%s was seen in %s saying, \"%s\" %s" % [d[:who],d[:where],d[:what],timestamp]
    when 'action'
      "%s was seen in %s using an action, \"%s\" %s" % [d[:who],d[:where],d[:what],timestamp]
    when 'quit'
      "%s was seen quiting IRC with message, \"%s\" %s" % [d[:who],d[:what],timestamp]
    when 'join'
      "%s was seen joining %s %s" % [d[:who],d[:where],timestamp]
    when 'part'
      "%s was seen leaving %s with message, \"%s\" %s" % [d[:who],d[:where],d[:what],timestamp]
    when 'op'
      "%s was seen getting OP in %s by %s %s" % [d[:who],d[:where],d[:operator],timestamp]
    when 'deop'
      "%s was seen losing OP in %s by %s %s" % [d[:who],d[:where],d[:operator],timestamp]
    when 'kick'
      "%s was seen getting kicked out of %s by %s with message, \"%s\" %s" % [d[:who],d[:where],d[:operator],d[:what],timestamp]
    when 'ban'
      "%s was banned in %s by %s (%s) %s" % [d[:who],d[:where],d[:operator],d[:what],timestamp]
    when 'unban'
      "%s was unbanned in %s by %s (%s) %s" % [d[:who],d[:where],d[:operator],d[:what],timestamp]
    when 'voice'
      "%s was voiced in %s by %s %s" % [d[:who],d[:where],d[:operator],timestamp]
    when 'devoice'
      "%s was devoiced in %s by %s %s" % [d[:who],d[:where],d[:operator],timestamp]
    when 'away'
      "%s went away with message, \"%s\" %s" % [d[:who],d[:what],timestamp]
    when 'unaway'
      "%s came back from away %s" % [d[:who],timestamp]
    end
  end

  def backup_data!
    log("===== Backing up !seen data from memory to disk =====", :info)
    log(@users.inspect, :debug)
    DataStash.store @users, './tmp/seen-users.stash'
  end

  def execute(m, nick)
  puts @users

    if nick.downcase == @bot.nick.downcase
      m.reply("That's me!",true)
    elsif nick.downcase == m.user.nick.downcase
      m.reply("That's you!",true)
    elsif @users.key?(nick.downcase.to_sym)
      m.reply(seen_reply(@users[nick.downcase.to_sym]),true)
    else
      m.reply("I haven't seen #{nick}",true)
    end
    backup_data!
  end

end
