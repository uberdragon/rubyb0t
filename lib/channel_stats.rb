require 'open-uri'
require 'nokogiri'
require 'cgi'

class ChannelStats

	include Cinch::Plugin

  listen_to :channel, method: :collect_word_count

	match /top10/, method: :topten_trigger

  timer 620, method: :backup_data! # 10 minutes

	def initialize(*args)
		super
    @wordcount = DataStash.load './tmp/channel-word-counts.stash' || {}
    log("===== Loading !top10 Data from Disk into Memory =====", :info)
    log(@wordcount.inspect, :debug)
	end

	def get_stats(channel)
		@nicks = @wordcount[channel.downcase.to_sym]
		@nicks = @nicks.sort {|a1,a2| a2[1]<=>a1[1]}

		output = ''

		@nicks.each_with_index do |nick,i|
			place = i + 1

			if i < 10
				case place
				when 1
					placement = '1st'
				when 2
					placement = '2nd'
				when 3
					placement = '3rd'
				else
					placement = "#{place}th"
				end

				output += "#{placement}: #{nick[0]} [#{nick[1]}] "
			end
		end

		if @nicks.length < 11
			total_nicks = @nicks.length
		elsif @nicks.length > 10
			total_nicks = 10
		end

		return "Top #{total_nicks} Chatter#{Utils.pluralize(total_nicks)} by Total Spoken Words: #{output}"

	end


	def collect_word_count(m)
		old_count = current_count(m.channel.name, m.user.nick)
		this_count = Utils.strip(m.message).split.length
		new_count = old_count.to_i + this_count.to_i
		build_data(m.channel.name, m.user.nick, new_count)
	end

	def topten_trigger(m)
		backup_data!
		m.reply(get_stats(m.channel.name), true)
	end

	def current_count channel, nickname
		if @wordcount[channel.downcase.to_sym].nil?
			@wordcount[channel.downcase.to_sym] = {}
			return 0
		end

		chan_data = @wordcount[channel.downcase.to_sym]

		if chan_data.empty?
			return 0
		else
			return chan_data[nickname.downcase.to_sym] || 0
		end
	end

  def backup_data!
    log("===== Backing up !top10 data from memory to disk =====", :info)
    log(@wordcount.inspect, :debug)
    DataStash.store @wordcount, './tmp/channel-word-counts.stash'
  end

  def build_data channel, nickname, word_count
    chan_data = @wordcount[channel.downcase.to_sym] 
    chan_data[nickname.downcase.to_sym] = word_count
    log("Storing #{channel}, #{nickname} now has #{word_count} words spoken", :debug)
  end

end
