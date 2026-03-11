# frozen_string_literal: true

# Send the cron output to container STDOUT so it's accessible in CloudWatch log streams
set :output, '/proc/1/fd/1'

ENV.each { |k, v| env k.to_sym, v }
set :environment, ENV.fetch('RAILS_ENV', 'production')

# for debugging cron jobs
# set :output, "#{path}/log/cron.log"

every 5.minutes do
  rake 'alerts:fetch'
end

# Clean up anonymous search records > 7 days
every :wednesday, at: '2:00am' do
  rake 'blacklight:delete_old_searches[7]'
end

# Clean up guest users > 7 days
every :wednesday, at: '4:00am' do
  rake 'devise_guests:delete_old_guest_users[7]'
end
