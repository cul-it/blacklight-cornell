scheduler = Rufus::Scheduler.new
scheduler.cron '45 01 * * *' do
  # :nocov:
    Rails.logger.info("Calling Databases.update #{Time.now}")
  # :nocov:

  Databases.update
end
