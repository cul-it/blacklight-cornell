# Be sure to restart your server when you modify this file.
#this is the url shortener. 
Rails.application.config.url_shorten  = ENV['URL_SHORTEN'] ? ENV['URL_SHORTEN'] : ""
