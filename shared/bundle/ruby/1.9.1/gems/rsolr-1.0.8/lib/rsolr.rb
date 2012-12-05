$: << "#{File.dirname(__FILE__)}" unless $:.include? File.dirname(__FILE__)

require 'rubygems'

module RSolr
  
  %W(Response Char Client Error Connection Uri Xml).each{|n|autoload n.to_sym, "rsolr/#{n.downcase}"}
  
  def self.version; "1.0.8" end
  
  VERSION = self.version
  
  def self.connect *args
    driver = Class === args[0] ? args[0] : RSolr::Connection
    opts = Hash === args[-1] ? args[-1] : {}
    Client.new driver.new, opts
  end
  
  # RSolr.escape
  extend Char
  
end