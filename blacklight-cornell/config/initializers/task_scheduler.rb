scheduler = Rufus::Scheduler.new
scheduler.cron '45 01 * * *' do
#scheduler.every '3m' do
  Rails.logger.info("Calling Databases.update #{Time.now}")
  Databases.update
end
