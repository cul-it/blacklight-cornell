StatusPage.configure do
  # Cache check status result 10 seconds
  self.interval = 10
  # Use service
  self.use :database
  self.use :cache
  # self.use :redis
  # Custom redis url
  # self.use :redis, url: ENV['REDIS_SESSION_HOST']
  # self.use :sidekiq
  # self.add_custom_service(CustomService)
  self.add_custom_service(CatalogSolr)
  self.add_custom_service(RepositoriesSolr)
  self.add_custom_service(FolioPatron)
  self.add_custom_service(IlliadTransactions)
  self.add_custom_service(ReshareStatus)
end
