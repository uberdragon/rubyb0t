require 'zlib'
require 'cinch'

# Saves any hash as YAML to disk!
# with optional gzip compression

class YamlStash
  include Cinch::Plugin

  def self.store hash, file_name, options={}
    yaml_dump = YAML::dump(hash)
    file = File.new(file_name,'w')
    file.write yaml_dump
    file.close
    return obj
  end

  def self.load file_name
    begin
      file = File.open(file_name, 'r')
    rescue
      YamlStash.store({}, file_name)
      file = File.open(file_name, 'r')
    ensure
      hash = YAML::load file.read
      file.close
    end
    return hash
  end
  
end
