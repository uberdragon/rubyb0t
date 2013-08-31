require 'cinch'

class Admin
  include Cinch::Plugin

  match /join (.+)/, method: :join
  match /part(?: (.+))?/, method: :part

  match /chan_op(?: (.+))?/, method: :channel_op
  match /op(?: (.+))?/, method: :op
  match /deop(?: (.+))?/, method: :deop

  match /kick(?: (.+))?/, method: :kick
# match /ban(?: (.+))?/, method: :ban

  match /voice(?: (.+))?/, method: :voice
  match /devoice(?: (.+))?/, method: :devoice

  match /nick (.+)/, method: :nick_change
  match /nick_check/, method: :nick_check
  match /ident/, method: :ident
  match /msg (.+?) (.+)/, method: :message
  match /quit(.+?)/, method: :quit

  listen_to :op, method: :saw_op

  timer 60*30, method: :nick_check

  def initialize(*args)
    super

    @op_nicks_queue = {}
    @voice_nicks_queue = {}

    @channels = {} # Initialize the hash

    @channels['#uber|dragon'.to_sym] = {
      :admins => [] + $global_admins,
      :sops => ['Ubie'] + $global_sops,
      :aops => [] + $global_aops,
      :voices => ['KhashayaR'] + $global_voices,
      :akick_list => [] + $global_akicks,
      :ban_list => [] + $global_bans
    }

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

  #####################  Trigger Methods #############################

  ############## GLOBAL ADMIN ONLY ###################

  def quit(m)
    return unless user_is_admin?(m.user)
    @bot.quit(m.message.split[1..-1].join(" "))
  end

  def message(m, receiver, message)
    return unless user_is_admin?(m.user)
    User(receiver).send(message)
  end

  def nick_change(m, nick)
    return unless user_is_admin?(m.user)
    @bot.nick = nick
  end

  def join(m, channel)
    return unless user_is_admin?(m.user)
    Channel(channel).join
  end

  def part(m, channel)
    return unless user_is_admin?(m.user)
    channel ||= m.channel
    Channel(channel).part if channel
  end

  def channel_op(m, input) # channel then nickname
    if !input.to_s.empty?
      options = input.split
      channel = options[0] if options.length > 1
      nick = options[1] if options.length > 1
      nick = options[0] if options.length == 1
    end
    channel = channel ||= m.channel
    nick = nick ||= @bot.nick

    return unless user_has_access?(m.user,channel,:sop)
    @chanserv.send "op #{channel} #{nick}"
  end

  def op(m, input)

    unless input.to_s.empty?
      options = input.split
      if options.length > 1
        channel = options[0]
        nick = options[1]
      end
      nick = options[0] if options.length == 1
    end
    channel = channel ||= m.channel
    nick = nick ||= m.user

    return unless user_has_access?(m.user,channel,:aop)

    if Channel(channel).opped?(nick)
      m.reply "#{nick} is already opped"
      return
    end

    if bot_has_ops?(channel)
      Channel(channel).op(nick)
    else
      m.reply "I'm not an OP... attempting to fix that anomaly... >:)"
      @chanserv.send "op #{channel} #{@bot.nick}"
      if @op_nicks_queue[channel].nil?
        @op_nicks_queue[channel] = []
      end
      @op_nicks_queue[channel].push(nick) if nick != @bot.nick  && !@op_nicks_queue[channel].include?(nick)
      log("Don't have OP in #{channel} so queing #{nick} for OP when I do")
    end

  end

  def deop(m, nick)
    return unless user_has_access?(m.user,m.channel,:aop)
    m.channel.deop(nick)
  end

  def kick(m, nick)
    return unless user_has_access?(m.user,m.channel,:aop) && nick != @bot.nick
    m.channel.kick(nick)
  end

  def voice(m, input)
    unless input.to_s.empty?
      options = input.split
      if options.length > 1
        channel = options[0]
        nick = options[1]
      end
      nick = options[0] if options.length == 1
    end
    channel ||= m.channel
    nick ||= m.user

    return unless user_has_access?(m.user,channel,:voice)

    if bot_has_ops?(channel)
      Channel(channel).voice(nick)
    else
      m.reply "I'm not an OP... attempting to fix that anomaly... >:)"
      @chanserv.send "op #{channel} #{@bot.nick}"
      log("obtaining ops for voice operation", :info)

      @voice_nicks_queue[channel] = [] if @voice_nicks_queue[channel].nil?

      @voice_nicks_queue[channel].push(nick) if nick != @bot.nick && !@voice_nicks_queue[channel].include?(nick)

      log("Don't have OP in #{channel} so queing #{nick} for VOICE when I do")
    end

  end

  def devoice(m, input)
    unless input.to_s.empty?
      options = input.split
      if options.length > 1
        channel = options[0]
        nick = options[1]
      end
      nick = options[0] if options.length == 1
    end
    channel = channel ||= m.channel
    nick = nick ||= m.user

    return unless user_has_access?(m.user,channel,:voice)
    m.channel.devoice(nick)
  end

  def ident(m)
    return unless user_is_admin?(m.user)
    @nickserv.send "identify %s" % [$settings[:password]]
    m.reply "I have identified to nickserv!"
  end

  ###################  Event Methods #####################

  def saw_op(m, nick)
    channel = m.params[0]

    log(channel, :info)

    if nick == @bot.nick
      log("-=-=-= I got opped in #{m.channel} -=-=-=")
      unless @op_nicks_queue[m.channel].nil? || @op_nicks_queue[m.channel].empty?
        log("*** Starting Op Queue for #{m.channel} ***", :info)
        @op_nicks_queue[m.channel].each do |nick|
          log("* #{nick} getting oped if needed", :info)
          Channel(m.channel).op(nick) if !Channel(m.channel).opped?(nick)
        end
        @op_nicks_queue.tap {|c| c.delete(m.channel)}
      end

      unless @voice_nicks_queue[m.channel].nil? || @voice_nicks_queue[m.channel].empty?
        log("*** Starting Voice Queue for #{m.channel} ***",:info)
        @voice_nicks_queue[m.channel].each do |nick|
          log("* #{nick} getting voiced if needed",:info)
          m.channel.voice(nick) if !Channel(m.channel).voiced?(nick)
        end
        @voice_nicks_queue.tap {|c| c.delete(m.channel)}
      end
    end
  end

  ####################  Helper Methods ####################

  def nick_check
    unless @bot.nick == $settings[:nick]
      m.reply 'Fixing nick.'
      @bot.nick = $settings[:nick]
    end
  end

  def bot_has_ops?(channel,nick=@bot.nick)
    Channel(channel).opped? nick
  end

  def user_has_access?(user,channel,type) # type => :owner, :sop, :aop, :voice
    user.refresh
    channel = channel.name.downcase.to_sym

    if @channels.include?(channel)
      c = @channels[channel]
      case type
      when :admin
        c[:admins].include?(user.nick) || $global_admins.include?(user.nick)
      when :sop
        c[:sops].include?(user.nick) || c[:admins].include?(user.nick)
      when :aop
        c[:aops].include?(user.nick) || c[:sops].include?(user.nick) || c[:admins].include?(user.nick)
      when :voice
        c[:voices].include?(user.nick) || c[:aops].include?(user.nick) || c[:sops].include?(user.nick) || c[:admins].include?(user.nick)
      end
    else
      case type
      when :admin
        $global_admins.include?(user.nick)
      when :sop
        $global_sops.include?(user.nick) || $global_admins.include?(user.nick)
      when :aop
        $global_aops.include?(user.nick) || $global_sops.include?(user.nick) || $global_admins.include?(user.nick)
      when :voice
        $global_voices.include?(user.nick) || $global_aops.include?(user.nick) || $global_sops.include?(user.nick) || $global_admins.include?(user.nick)
      end
    end
  end

end
