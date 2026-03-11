# This module registers the RIS export format with the system so that we
# can offer export options for Mendeley and Zotero.
module Blacklight::Document::Export::Ris

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Document::Export::Ris.register_export_formats( document )
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
    "MPCT"=>"MPCT", "MULTI"=>"MULTI", "Musical Score"=>"MUSIC", "NEWS"=>"NEWS",
    "PAMP"=>"PAMP", "PAT"=>"PAT", "PCOMM"=>"PCOMM", "RPRT"=>"RPRT",
    "SER"=>"SER", "SLIDE"=>"SLIDE", "Non-musical Recording"=>"SOUND", "Musical Recording"=>"SOUND",
    "STAND"=>"STAND",
    "STAT"=>"STAT", "Thesis"=>"THES", "UNPB"=>"UNPB", "Video"=>"VIDEO"
  }

  def export_ris
    return nil unless exportable_record?

    # Determine type (TY) of format
    # but for now, go with generic (that's what endnote is doing)

    fmt = export_format
    ty = FACET_TO_RIS_TYPE[fmt] || "GEN"
    ty = "EBOOK" if fmt == "Book" && export_online?
    output = +"TY  - #{ty}\n"

    # Handle title
    title = export_title(separator: ": ")
    output << "TI  - #{title}\n" if title.present?

    # Handle authors
    authors = export_contributors || {}
    # authors can contain primary_authors, editors, translators, and compilers
    # each one is an array. Oddly, though, RIS format doesn't seem to provide
    # for anything except 'author'
    primary_authors = authors[:primary_authors] || []
    corp_authors = (authors[:primary_corporate_authors] || []) + (authors[:secondary_corporate_authors] || [])
    editors = authors[:editors] || []
    if primary_authors.present?
      output << "AU  - #{primary_authors[0]}\n"
      primary_authors.drop(1).each_with_index do |author, index|
        output << "A#{index + 1}  - #{author}\n"
      end
    end

    if primary_authors.blank? && corp_authors.present? && editors.blank?
      output << "AU  - #{corp_authors[0]}\n"
      corp_authors.drop(1).each_with_index do |author, index|
        output << "A#{index + 1}  - #{author}\n"
      end
    end

    editors.each { |e| output << "ED  - #{e}\n" }

    # publication year
    pub_data = export_publication_data || {}
    output << "PY  - #{pub_data[:date]}\n"

    # publisher, and treatment of thesis publisher.
    publisher = pub_data[:publisher]
    place = pub_data[:place]
    thtype = ""
    if fmt == "Thesis"
      thdata = export_thesis_info
      if thdata.present?
        publisher = thdata[:inst].to_s if thdata[:inst].present?
        thtype = thdata[:type].to_s
      end
    end
    output << "PB  - #{publisher}\n" if publisher.present?
    output << "CY  - #{place}\n" if place.present?
    output << "M3  - #{thtype}\n" if thtype.present?
    # edition
    et = export_edition
    output << "ET  - #{et}\n" if et.present?
    # language
    export_languages.each { |la| output << "LA  - #{la}\n" }

    ul = export_access_url
    output << "UR  - #{ul}\n" if ul.present?

    catalog_url = export_catalog_url
    if catalog_url.present?
      output << "M2  - #{catalog_url}\n"
      output << "N1  - #{catalog_url}\n"
    end

    doi = export_doi
    output << "DO  - #{doi}\n" if doi.present?

    export_keywords.each { |k| output << "KW  - #{k}\n" unless k.empty? }
    export_notes.each { |n| output << "N1  - #{n}\n" }
    export_abstracts.each { |n| output << "N2  - #{n}\n" }

    holdings = export_holdings || []
    output << "CN  - #{holdings.join(' ')}\n" unless holdings.join("").blank?

    isbns = export_isbns || []
    output << "SN  - #{isbns.join(' ')}\n" unless isbns.join("").blank?
    # closing tag
    output += "ER  - \n"

    output
  end
end
