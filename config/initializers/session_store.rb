# Be sure to restart your server when you modify this file.

#BlacklightCornell::Application.config.session_store :cookie_store, key: '_blacklightcornell_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# WAS
if ENV['REDIS_SESSION_HOST']
  ActiveRecord::SessionStore::Session.attr_accessible :data, :session_id
  BlacklightCornell::Application.config.session_store :redis_session_store, {
  key: '_blacklightcornell_session',
  redis: {
    db: 2,
    expire_after: 10.minutes,
    key_prefix: 'blacklightcornell:session:',
#    host: 'newcatalog-test.49jyrp.0001.use1.cache.amazonaws.com', # Redis host name, default is localhost
    host: ENV['REDIS_SESSION_HOST'],
    port: ENV['REDIS_SESSION_PORT']    # Redis port, default is 6379
  }
}
else 
  BlacklightCornell::Application.config.session_store  :active_record_store,   {:expire_after => 30.minutes }

end
