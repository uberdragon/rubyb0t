require 'cinch'

class DataStash
  include Cinch::Plugin

  def self.store obj, file_name, options={}
    json_dump = obj.to_json
    file = File.new(file_name,'w')
    file.write json_dump
    file.close
    return obj
  end

  def self.load file_name

    begin
      file = File.open(file_name, 'r')
    rescue
      data = Hash.new
      data[:creation] = {:date => Time.now.asctime}
      DataStash.store(data.to_json, file_name)
      file = File.open(file_name, 'r')
    ensure
      obj = JSON.parse(file.read, :symbolize_names => true)
      file.close
    end
    return obj
  end
  
end
