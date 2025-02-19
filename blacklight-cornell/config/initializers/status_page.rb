  StatusPage.configure do
    self.interval = 10
    self.use :database
    self.use :cache
    self.add_custom_service(Status::CatalogSolr)
    self.add_custom_service(Status::RepositoriesSolr)
    self.add_custom_service(Status::FolioPatron)
    self.add_custom_service(Status::IlliadStatus)
    self.add_custom_service(Status::ReshareStatus)
  end
