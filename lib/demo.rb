require 'json'

class Demo
  include Cinch::Plugin

  match /demo qa (.+)/, method: :demo_qa

  def demo(m, command)
    m.reply "You tried to run #{command}"
  end

  def demo_qa(m, domain)
  	api_key = "AD34FA3F-8486-4A2F-AA6C-D403BDD93485"
    url = "http://crm.searchinfluence.com/qa_considerations.php?domain=#{domain}&api_key=#{api_key}"
    buffer = open(url).read
    result = JSON.parse(buffer)

    if result['error'].nil? && !result['description'].nil?
      m.reply result['description']
    elsif !result['error'].nil?
      m.reply result['error']
    end
  end
end
