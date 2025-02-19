StatusPage.configure do
  # Cache check status result 10 seconds
  self.interval = 10
  # Use service
  self.use :database
  self.use :cache
  self.add_custom_service(CatalogSolr)
  self.add_custom_service(RepositoriesSolr)
  # self.add_custom_service(FolioPatron)
  # self.add_custom_service(IlliadTransactions)
  # self.add_custom_service(ReshareStatus)
  self.add_custom_service(MyAccountService)
end
