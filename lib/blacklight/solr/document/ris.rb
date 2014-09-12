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


  def export_as_mendeley

    export_ris

  end

  def export_as_zotero

    export_ris

  end

  def export_ris

    # Determine type (TY) of format
    # but for now, go with generic (that's what endnote is doing)
    output = 'TY  - GEN' + "\n"
    
    # Handle title
    output += "TI  - #{clean_end_punctuation(setup_title_info(to_marc))}\n"

    # Handle authors
    authors = get_all_authors(to_marc)
    # authors can contain primary_authors, editors, translators, and compilers
    # each one is an array. Oddly, though, RIS format doesn't seem to provide
    # for anything except 'author'
    primary_authors = authors[:primary_authors]
    output += "AU  - #{primary_authors[0]}\n"
    if primary_authors.length > 1
      for i in 1..primary_authors.length
        output += "A#{i}  - #{primary_authors[i]}"
      end
    end

    # publication year
    output += "PY  - #{setup_pub_date(to_marc)}\n"

    # publisher
    pub_data = setup_pub_info(to_marc) # This function combines publisher and place
    if !pub_data.nil?
      place, publisher = pub_data.split(':')
      output += "PB  - #{publisher.strip!}\n"

      # publication place
      output += "CY  - " + place + "\n"
    end

    # edition
    output += "ET  - #{setup_edition(to_marc)}\n"

    # closing tag
    output += "ER  - "

    output

  end

end