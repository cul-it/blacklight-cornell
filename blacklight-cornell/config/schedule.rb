# frozen_string_literal: true

ENV.each { |k, v| env(k, v) }

# for debugging cron jobs
# set :output, "#{path}/log/cron.log"

every 5.minutes do
  rake 'alerts:fetch'
end
