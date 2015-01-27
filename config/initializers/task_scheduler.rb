scheduler = Rufus::Scheduler.new
scheduler.cron '05 01 * * *' do
#scheduler.every '3m' do
  Databases.update
end
