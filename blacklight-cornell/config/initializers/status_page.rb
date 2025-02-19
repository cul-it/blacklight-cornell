  StatusPage.configure do
    self.interval = 10
    self.use :database
    self.use :cache
    self.add_custom_service(CatalogSolr)
    self.add_custom_service(RepositoriesSolr)
    self.add_custom_service(FolioPatron)
    self.add_custom_service(IlliadStatus)
    self.add_custom_service(ReshareStatus)
  end
