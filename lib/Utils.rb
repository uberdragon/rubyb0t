require 'cinch'

class Utils
  include Cinch::Plugin
  def self.seconds_to_string(s)

    # d = days, h = hours, m = minutes, s = seconds

    m = (s / 60).floor
    s = s % 60
    h = (m / 60).floor
    m = m % 60
    d = (h / 24).floor
    h = h % 24
    w = (d / 7).floor
    d = w % 7

    output = "0 seconds"
    output = "#{s} second#{Utils.pluralize(s)}" if (s > 0)
    output = "#{m} minute#{Utils.pluralize(m)}, #{s} second#{Utils.pluralize(s)}" if (m > 0)
    output = "#{h} hour#{Utils.pluralize(h)}, #{m} minute#{Utils.pluralize(m)}, #{s} second#{Utils.pluralize(s)}" if (h > 0)
    output = "#{d} day#{Utils.pluralize(d)}, #{h} hour#{Utils.pluralize(h)}, #{m} minute#{Utils.pluralize(m)}" if (d > 0)
    output = "#{w} week#{Utils.pluralize(w)}, #{d} day#{Utils.pluralize(d)}, #{h} hour#{Utils.pluralize(h)}" if (w > 0)

    return output
  end

  def self.pluralize number 
    return "s" unless number == 1
    return ""
  end

  def self.strip text_with_unicode
    if text_with_unicode == :none 
      return
    end
    output = text_with_unicode.to_s.gsub(/\x1f|\x02|\x12|\x0f|\x16|\x03(?:\d{1,2}(?:,\d{1,2})?)?/,"")
  end

end
