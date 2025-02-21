  StatusPage.configure do
    self.interval = 10
    self.use :database
    self.use :cache
    self.add_custom_service(Status::CatalogSolrStatus)
    self.add_custom_service(Status::RepositoriesSolrStatus)
    self.add_custom_service(Status::FolioPatronStatus)
    self.add_custom_service(Status::FolioRequestStatus)
    self.add_custom_service(Status::IlliadStatus)
    self.add_custom_service(Status::ReshareStatus)
  end
