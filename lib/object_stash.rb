require 'zlib'

# Save any ruby object to disk!
# Objects are stored as gzipped marshal dumps.

class ObjectStash

  def self.store obj, file_name, options={}
    marshal_dump = Marshal.dump(obj)
    file = File.new(file_name,'w')
    file = Zlib::GzipWriter.new(file) unless options[:gzip] == false
    file.write marshal_dump
    file.close
    return obj
  end

  def self.load file_name
    unless File.exists?(file_name)
      puts "#{file_name} does not exist for stashing..  trying to create.."
      ObjectStash.store({},file_name)
    end
    begin
      file = Zlib::GzipReader.open(file_name)
    rescue Zlib::GzipFile::Error
      file = File.open(file_name, 'r')
    ensure
      hash = Marshal.load file.read
      file.close
      return hash
    end
  end
  
end
