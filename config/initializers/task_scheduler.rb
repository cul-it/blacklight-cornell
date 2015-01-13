scheduler = Rufus::Scheduler.new
scheduler.cron '35 11 * * 2' do
#scheduler.every '3m' do
  Databases.update
end
