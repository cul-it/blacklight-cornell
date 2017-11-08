
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
    @r.rpush  @bagname,value
  end


  def delete(value)
    @r.lrem  @bagname,99,value
  end

  def index
    @r.lrange(@bagname, 0, -1)
  end

  def count 
    @r.llen(@bagname)
  end

end

#BAG_REDIS_HOST=elasticache-001.internal.library.cornell.edu
#BAG_REDIS_PORT=6379
#BAG_REDIS_DB=2

