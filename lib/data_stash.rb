require 'cinch'
require 'json'

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
      if data.nil?
        obj = JSON.parse(file.read, :symbolize_names => true)
      else
        obj = JSON.parse(eval(file.read), :symbolize_names => true)
        DataStash.store(obj,file_name)
      end
      file.close
    end
    return obj
  end
  
end
