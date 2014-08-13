# This module registers the RIS export format with the system so that we
# can offer export options for Mendeley and Zotero.
module Blacklight::Solr::Document::RIS
  
  def self.extended(document)
    # Register our exportable formats
    Blacklight::Solr::Document::RIS.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:mendeley, "application/x-research-info-systems")
    document.will_export_as(:zotero, "application/x-research-info-systems")
  end

end