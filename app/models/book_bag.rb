require 'mysql2'
require 'dotenv'
# CREATE TABLE book_bags
# (bagname varchar(255),
# bibid int unsigned,
# PRIMARY KEY (bagname, bibid));

class BookBag

  attr_accessor :bagname

  Dotenv.load!

  if ENV['BAG_MYSQL_HOST'].present?
    @@con = Mysql2::Client.new(:host => ENV['BAG_MYSQL_HOST'],
            :username => ENV['BAG_MYSQL_USER'],
            :password => ENV['BAG_MYSQL_PASSWORD'],
            :database => ENV['BAG_MYSQL_DATABASE'] )
    @@bagname = nil

    begin
      @@con.query("CREATE TABLE IF NOT EXISTS \
        book_bags(bagname varchar(255), bibid int unsigned, PRIMARY KEY (bagname, bibid))")
    rescue Mysql2::error => e
      @@con = nil
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in BookBag"
      puts e.error.to_yaml
      puts e.errno.inspect
      Rails.logger.level = save_level
    end

  else
    @@con = nil
  end

  def initialize(bagname)
    @con = @@con
    if bagname.present?
      if bagname.to_s.match(/^[0-9a-zA-Z@\-_]+$/)
        @bagname = bagname
        @@bagname = bagname
      else
        raise 'invalid bookbag name: (' + bagname + ')'
      end
    end
  end

  def self.enabled?
   return !@@con.nil?
  end

  def enabled?
   return !@con.nil?
  end

  def create(value)
    begin
      if @con
      end
      if value.is_a? Integer
        @con.query("INSERT INTO book_bags(bagname,bibid) VALUES('#{@bagname}','#{value}')")
      end
      # @con.rpush  @bagname,value if @con
    rescue
      Rails.logger.error("BookBag connect error:  #{__FILE__}:#{__LINE__}  value = #{value.inspect}")
      @@con = nil
      @con = nil
    end
  end


  def delete(value)
    begin
      @con.query("DELETE FROM book_bags WHERE bagname='#{@bagname}' AND value='#{value}'")
      # @con.lrem  @bagname,99,value if @con
    rescue
      Rails.logger.error("BookBag connect error:  #{__FILE__}:#{__LINE__}  value = #{value.inspect}")
      @@con = nil
      @con = nil
    end
  end

  def index
    c = []
    begin
      bibs = @con.query("SELECT bibid FROM book_bags WHERE bagname='#{@bagname}'")
      bibs.each do |bib|
        c << bib
      end
      # c = @con.lrange(@bagname,0,-1) if @con
    rescue
      Rails.logger.error("BookBag connect error:  #{__FILE__}:#{__LINE__}  @con = #{@con.inspect}")
      c =[]
      @@con = nil
      @con = nil
    end
    c
  end

  def count
    #@con.llen(@bagname)
    c = 0
    begin
      bibs = @con.query("SELECT bibid FROM book_bags WHERE bagname='#{@bagname}'")
      c = bibs.num_rows
      # c = @con.lrange(@bagname,0,-1).uniq.size if @con
    rescue
      Rails.logger.error("BookBag connect error:  #{__FILE__}:#{__LINE__}  @con = #{@con.inspect}")
      c = 0
      @@con = nil
      @con = nil
    end
    c
  end

  def clear
    c = 0
    begin
      @con.query("DELETE FROM book_bags WHERE bagname='#{@bagname}'")
      c = con.affected_rows
      # c = @con.del(@bagname,0)  if @con
    rescue
      Rails.logger.error("BookBag connect error:  #{__FILE__}:#{__LINE__}  @con = #{@con.inspect}")
      c = 0
      @@con = nil
      @con = nil
    end
    c
  end

end
