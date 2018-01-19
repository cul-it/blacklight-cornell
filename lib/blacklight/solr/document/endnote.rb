# This module registers the Endnote tagged export format with the system so that we
# can offer export options for Mendeley and Zotero.
module Blacklight::Solr::Document::Endnote

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Solr::Document::RIS.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:endnote, "application/x-endnote-refer")
  end


end
