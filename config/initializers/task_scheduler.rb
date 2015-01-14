scheduler = Rufus::Scheduler.new
scheduler.cron '05 1 * * *' do
#scheduler.every '3m' do
  Databases.update
end
