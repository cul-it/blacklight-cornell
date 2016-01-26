# Be sure to restart your server when you modify this file.

#BlacklightCornell::Application.config.session_store :cookie_store, key: '_blacklightcornell_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
BlacklightCornell::Application.config.session_store  :active_record_store,  :expire_after => 10.minutes 
ActiveRecord::SessionStore::Session.attr_accessible :data, :session_id
