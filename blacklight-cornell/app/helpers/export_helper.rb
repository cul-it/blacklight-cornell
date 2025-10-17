module ExportHelper
  # Use this module for any export helper logic

  # ============================================================================
  # Returns true if the Solr document originated from FOLIO (non-MARC).
  # ----------------------------------------------------------------------------
  def folio_record?(document)
    true if document['source'].to_s.strip.casecmp?('folio')
  end
end