module Blacklight::Solr::Document::RIS
  
  def self.extended(document)
    # Register our exportable formats
    Rails.logger.warn "mjc12test: call1"
    Blacklight::Solr::Document::RIS.register_export_formats( document )
  end

  def self.register_export_formats(document)
    Rails.logger.warn "mjc12test: call2"
    document.will_export_as(:mendeley, "text/plain")
    document.will_export_as(:zotero, "text/plain")
  end

end