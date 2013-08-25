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
  match /msg (.+)/, method: :message
  match /msg (.+?) (.+)/, method: :message
  match /quit (.+?)/, method: :quit

  listen_to :op, method: :saw_op

  #match "You're not channel operator", method: :self_op

  timer 60*30, method: :nick_check




  def initialize(*args)
    super

    @op_nicks_queue = {}

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

  #####################  Trigger Methods #############################
  def quit(m)
    return unless check_user(m.user)
    @bot.quit(m.message.split[1..-1].join(" "))
    sleep(30)
    Thread.new do
      @bot.start
    end
  end

  def message(m, receiver, message)
    return unless check_user(m.user)
    User(receiver).send(message)
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

    if Channel(channel).opped?(nick)
      m.reply "#{nick} is already opped"
      return
    end

    if bot_has_ops?(channel)
      Channel(channel).op(nick)
    else
      m.reply "I'm not an OP... attempting to fix that anomaly... >:)"
      @chanserv.send "op #{channel} #{@bot.nick}"
      if @op_nicks_queue[channel].nil? && nick != @bot.nick
        @op_nicks_queue[channel] = []
        @op_nicks_queue[channel].push(nick)
      else
        @op_nicks_queue[channel].push(nick)
      end
      puts "Don't have OP in #{channel} so queing #{nick} for OP when I do"
      puts "#{@op_nicks_queue}"
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

  ###################  Event Methods #####################

  def saw_op(m, nick)
    if nick == @bot.nick
      puts "-=-=-= I got opped in #{m.channel} -=-=-="
      unless @op_nicks_queue[m.channel].nil?
        puts "*** Starting Op Queue for #{m.channel} ***"
        @op_nicks_queue[m.channel].each do |nick|
          puts "* #{nick} getting oped if needed"
          Channel(m.channel).op(nick) if !Channel(m.channel).opped?(nick)
        end
        @op_nicks_queue.tap {|c| c.delete(m.channel)}
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
end
