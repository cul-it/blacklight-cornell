# Be sure to restart your server when you modify this file.

# Contains initialization for locations
require 'location'
if ActiveRecord::Base.connection.table_exists? :locations
  begin
    LOCATIONS_CONFIG = YAML.load_file("#{::Rails.root}/config/locations.yml")
    LOCATIONS_CONFIG['locations'].each do |loc|
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} loc =  #{loc.inspect}")
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
jgr25_context = "#{__FILE__}:#{__LINE__}"
Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << jgr25_context
msg << "loc: " + loc.inspect
msg << 'Z' * 60
msg.each { |x| puts 'ZZZ ' + x.to_yaml }
Rails.logger.level = save_level
#binding.pry
#*******************
      d = loc[1]
      query_hash = { voyager_id: d['voyager_id'] }
      voyager_id = d["voyager_id"].nil? ? 0 : d["voyager_id"]
      l=0
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
jgr25_context = "#{__FILE__}:#{__LINE__}"
Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << jgr25_context
msg << "voyager_id: " + voyager_id.inspect
msg << "query_hash: " + query_hash.inspect
msg << 'Z' * 60
msg.each { |x| puts 'ZZZ ' + x.to_yaml }
Rails.logger.level = save_level
#binding.pry
#*******************
      l = Location.exists?(query_hash)
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
jgr25_context = "#{__FILE__}:#{__LINE__}"
Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << jgr25_context
msg << " l: " +  l.inspect
msg << 'Z' * 60
msg.each { |x| puts 'ZZZ ' + x.to_yaml }
Rails.logger.level = save_level
#binding.pry
#*******************
#jgr Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} l =  #{l.inspect}")
      if (l)
        r = Location.where(query_hash)
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
