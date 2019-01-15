
class Bookbag 

  attr_accessor :bagname

  if ENV['BAG_REDIS_HOST'] 
    @@r = Redis.new(
             port: ENV['BAG_REDIS_PORT'], 
             host: ENV['BAG_REDIS_HOST'],
             db: ENV['BAG_REDIS_DB'] )
      @@bagname = nil 
  else
    @@r = nil
  end

  def initialize(bagname) 
    @r = @@r
    @bagname = bagname unless bagname.nil?
    @@bagname = bagname unless bagname.nil?
  end
  
  def self.enabled?
   return !@@r.nil?
  end

  def enabled?
   return !@r.nil?
  end

  def create(value)
    begin  
      if @r
      end
      @r.rpush  @bagname,value if @r
      rescue
        Rails.logger.error("Bookbag connect error:  #{__FILE__}:#{__LINE__}  value = #{value.inspect}")
        @@r = nil
        @r = nil
      end
  end


  def delete(value)
    begin  
      @r.lrem  @bagname,99,value if @r
    rescue
      Rails.logger.error("Bookbag connect error:  #{__FILE__}:#{__LINE__}  value = #{value.inspect}")
      @@r = nil
      @r = nil
    end
  end

  def index
    c = [] 
    begin  
      c = @r.lrange(@bagname,0,-1) if @r
    rescue 
      Rails.logger.error("Bookbag connect error:  #{__FILE__}:#{__LINE__}  @r = #{@r.inspect}")
      c =[] 
      @@r = nil
      @r = nil
    end
    c
  end

  def count 
    #@r.llen(@bagname)
    c = 0 
    begin  
      c = @r.lrange(@bagname,0,-1).uniq.size if @r
    rescue 
      Rails.logger.error("Bookbag connect error:  #{__FILE__}:#{__LINE__}  @r = #{@r.inspect}")
      c = 0
      @@r = nil
      @r = nil
    end
    c
  end

  def clear 
    c = 0
    begin  
      c = @r.del(@bagname,0)  if @r
    rescue 
      Rails.logger.error("Bookbag connect error:  #{__FILE__}:#{__LINE__}  @r = #{@r.inspect}")
      c = 0
      @@r = nil
      @r = nil
    end
    c
  end

end

#BAG_REDIS_HOST=elasticache-001.internal.library.cornell.edu
#BAG_REDIS_PORT=6379
#BAG_REDIS_DB=2

