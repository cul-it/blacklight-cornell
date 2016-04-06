# This module registers the RIS export format with the system so that we
# can offer export options for Mendeley and Zotero.
module Blacklight::Solr::Document::RIS
  
  def self.extended(document)
    # Register our exportable formats
    Blacklight::Solr::Document::RIS.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:ris, "application/x-research-info-systems")
    document.will_export_as(:mendeley, "application/x-research-info-systems")
    document.will_export_as(:zotero, "application/x-research-info-systems")
  end


  def export_as_ris
    export_ris
  end

  def export_as_mendeley
    export_ris
  end

  def export_as_zotero
    export_ris
  end

FACET_TO_RIS_TYPE =  { "ABST"=>"ABST", "ADVS"=>"ADVS", "AGGR"=>"AGGR",
  "ANCIENT"=>"ANCIENT", "ART"=>"ART", "BILL"=>"BILL", "BLOG"=>"BLOG",
  "Book"=>"BOOK", "CASE"=>"CASE", "CHAP"=>"CHAP", "CHART"=>"CHART",
  "CLSWK"=>"CLSWK", "COMP"=>"COMP", "CONF"=>"CONF", "CPAPER"=>"CPAPER",
  "CTLG"=>"CTLG", "DATA"=>"DATA", "Database"=>"DBASE", "DICT"=>"DICT",
  "EBOOK"=>"EBOOK", "ECHAP"=>"ECHAP", "EDBOOK"=>"EDBOOK", "EJOUR"=>"EJOUR",
  "ELEC"=>"ELEC", "ENCYC"=>"ENCYC", "EQUA"=>"EQUA", "FIGURE"=>"FIGURE",
  "GEN"=>"GEN", "GOVDOC"=>"GOVDOC", "GRANT"=>"GRANT", "HEAR"=>"HEAR",
  "ICOMM"=>"ICOMM", "INPR"=>"INPR", "JFULL"=>"JFULL", "JOUR"=>"JOUR",
  "LEGAL"=>"LEGAL", "Manuscript/Archive"=>"MANSCPT", "Map or Globe"=>"MAP", "MGZN"=>"MGZN",
  "MPCT"=>"MPCT", "MULTI"=>"MULTI", "Score"=>"MUSIC", "NEWS"=>"NEWS",
  "PAMP"=>"PAMP", "PAT"=>"PAT", "PCOMM"=>"PCOMM", "RPRT"=>"RPRT",
  "SER"=>"SER", "SLIDE"=>"SLIDE", "Non-musical Recording"=>"SOUND", "Musical Recording"=>"SOUND", 
  "STAND"=>"STAND",
  "STAT"=>"STAT", "THES"=>"THES", "UNPB"=>"UNPB", "Video"=>"VIDEO"
  }

  def export_ris
    # Determine type (TY) of format
    # but for now, go with generic (that's what endnote is doing)
    Rails.logger.warn "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{self['format'].inspect}"
    ty = "TY  - GEN\n"
    fmt = self['format'].first
    if (FACET_TO_RIS_TYPE.keys.include?(fmt))
      ty =  "TY  - #{FACET_TO_RIS_TYPE[fmt]}\n" 
    end
    output = ty 
    
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
      output += "PB  - #{publisher.strip!}\n" unless publisher.nil?

      # publication place
      output += "CY  - " + place + "\n"
    end

    # edition
    et =  setup_edition(to_marc)
    output += "ET  - #{et}\n" unless et.blank?
    # language 
    if !self["language_facet"].blank?
      self["language_facet"].map{|la|  output += "LA  - #{la}\n" }
    end
    catid   =  self.id 
    output += "UL  - http://newcatalog.library.cornell.edu/catalog/#{id}\n"

    # closing tag
    output += "ER  - "

    output

  end

end
