# Be sure to restart your server when you modify this file.

# Contains initialization for locations 
require 'location'
if ActiveRecord::Base.connection.table_exists? :locations
  begin
    LOCATIONS_CONFIG = YAML.load_file("#{::Rails.root}/config/locations.yml")
    LOCATIONS_CONFIG['locations'].each do |loc|  
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} loc =  #{loc.inspect}")
      d = loc[1]
      l = Location.exists?(voyager_id: d['voyager_id'])
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} l =  #{l.inspect}")
      if (l)  
        r = Location.where(voyager_id: d['voyager_id'])
        r.first.update(d)
      else
        nl = Location.new(d) 
        nl.save 
      end
       
    end
    
  rescue Errno::ENOENT
    puts <<-eos
  
    ******************************************************************************
    Your locations.yml config file is missing.
    See config/locations.yml.example
    ******************************************************************************
  
    eos
  
  
  end
  
end
