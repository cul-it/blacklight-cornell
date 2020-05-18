require 'mysql2'
require 'dotenv'
# CREATE TABLE book_bags
# (bagname varchar(255),
# bibid int unsigned,
# PRIMARY KEY (bagname, bibid));

class BookBag

  attr_accessor :bagname
  @@bagname = nil;

  def connect
    Dotenv.load!
    if ENV['BAG_MYSQL_HOST'].present?
      client = Mysql2::Client.new(:host => ENV['BAG_MYSQL_HOST'],
              :username => ENV['BAG_MYSQL_USER'],
              :password => ENV['BAG_MYSQL_PASSWORD'],
              :database => ENV['BAG_MYSQL_DATABASE'] )
    else
      raise 'Missing BookBag configuration.'
    end
  end

  def create_table
    begin
      client = connect
      client.query("CREATE TABLE IF NOT EXISTS \
        book_bags(bagname varchar(255), bibid int unsigned, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (bagname, bibid))")
    rescue Mysql2::Error => e
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in BookBag"
      puts e.error.to_yaml
      puts e.errno.inspect
      Rails.logger.level = save_level
    ensure
      client.close
    end
  end

  def initialize(bagname)
    if bagname.present?
      if bagname.to_s.match(/^[0-9a-zA-Z@\-_\.]+$/)
        @bagname = bagname
        @@bagname = bagname
      else
        raise 'BookBag initialize invalid bookbag name: (' + bagname + ')'
      end
    end
  end

  def self.enabled?
   return @@bagname.present?
  end

  def enabled?
   return @@bagname.present?
  end

  def create_all(list)
    begin
      client = connect
      statement = client.prepare("INSERT IGNORE INTO book_bags(bagname,bibid) VALUES(? , ?)")
      list.each do |bib|
        statement.execute(@bagname, bib)
      end
    rescue Mysql2::Error => e
      raise "BookBag create_all error: " + e.error
    ensure
      client.close unless client.nil?
    end
  end

  def delete_all(list)
    begin
      client = connect
      statement = client.prepare("DELETE FROM book_bags WHERE bagname = ? AND bibid = ?")
      list.each do |bib|
        statement.execute(@bagname, bib)
      end
    rescue Mysql2::Error => e
      raise "BookBag delete_all error: " + e.error
    ensure
      client.close unless client.nil?
    end
  end

  def index
    c = []
    begin
      client = connect
      bibs = client.query("SELECT bibid FROM book_bags WHERE bagname='#{@bagname}'")
      bibs.each do |bib|
        c << bib
      end
      # c = @con.lrange(@bagname,0,-1) if @con
    rescue Mysql2::Error => e
      raise "BookBag index error: " + e.error
    ensure
      client.close unless client.nil?
    end
    c
  end

  def count
    #@con.llen(@bagname)
    c = 0
    begin
      client = connect
      bibs = client.query("SELECT bibid FROM book_bags WHERE bagname='#{@bagname}'")
      c = bibs.count
      # c = @con.lrange(@bagname,0,-1).uniq.size if @con
    rescue Mysql2::Error => e
      raise "BookBag count error: " + e.error
    ensure
      client.close unless client.nil?
    end
    c
  end

  def clear
    c = 0
    begin
      client = connect
      client.query("DELETE FROM book_bags WHERE bagname='#{@bagname}'")
      c = con.affected_rows
      # c = @con.del(@bagname,0)  if @con
    rescue Mysql2::Error => e
      raise "BookBag count error: " + e.error
    ensure
      client.close unless client.nil?
    end
    c
  end

  def debug
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in BookBag debug"
    puts "@@bagname:\n" + @@bagname.to_yaml
    puts "@bagname:\n" + @bagname.to_yaml
    num  = self.count
    puts "Count:\n" + num.inspect
    bibs = self.index
    puts "Index:\n" + bibs.to_yaml
    # current_user, current_or_guest_user, user_session are all undefined
    Rails.logger.level = save_level
  end

  def export
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in authenticate"
    msg= "BookBag export"
    puts msg.to_yaml
    Rails.logger.level = save_level
    debug
  end


end
