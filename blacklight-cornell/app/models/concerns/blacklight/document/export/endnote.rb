# This module registers the Endnote tagged export format with the system so that we
# can offer export options for Mendeley and Zotero.
module Blacklight::Document::Export::Endnote

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Document::Export::Endnote.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:endnote, "application/x-endnote-refer")
  end

  FACET_TO_ENDNOTE_TYPE =  { "ABST"=>"ABST", "ADVS"=>"ADVS", "AGGR"=>"AGGR",
   "ANCIENT"=>"ANCIENT", "ART"=>"Artwork", "BILL"=>"Bill", "BLOG"=>"Blog",
   "Book"=>"Book", "CASE"=>"CASE", "CHAP"=>"CHAP", "CHART"=>"Map",
   "CLSWK"=>"CLSWK", "Computer File"=>"Computer Program", "CONF"=>"CONF", "CPAPER"=>"Conference Paper",
   "CTLG"=>"CTLG", "DATA"=>"DATA", "Database"=>"DBASE", "DICT"=>"DICT",
   "EBOOK"=>"Electronic Book", "ECHAP"=>"ECHAP", "EDBOOK"=>"EDBOOK", "EJOUR"=>"EJOUR",
   "ELEC"=>"ELEC", "ENCYC"=>"ENCYC", "EQUA"=>"EQUA", "FIGURE"=>"FIGURE",
   "GEN"=>"GEN", "GOVDOC"=>"GOVDOC", "GRANT"=>"GRANT", "HEAR"=>"Heading",
   "ICOMM"=>"ICOMM", "INPR"=>"INPR", "JFULL"=>"JFULL", "JOUR"=>"JOUR",
   "LEGAL"=>"LEGAL", "Manuscript/Archive"=>"Manuscript", "Map or Globe"=>"Map", "MGZN"=>"MGZN",
   "MPCT"=>"MPCT", "MULTI"=>"MULTI", "Musical Score"=>"GENERIC", "NEWS"=>"NEWS",
   "PAMP"=>"Pamphlet", "PAT"=>"Patent", "PCOMM"=>"PCOMM", "RPRT"=>"RPRT",
   "SER"=>"Serial Publication", "SLIDE"=>"SLIDE", "Non-musical Recording"=>"Audiovisual Material", "Musical Recording"=>"Music",
   "STAND"=>"Standard",
   "STAT"=>"Statute", "Thesis"=>"Thesis", "UNPB"=>"UNPB", "Video"=>"Film or Broadcast",
   "Website" => "Web Page"
   }

  def export_as_endnote
    return nil unless exportable_record?

    fmt = export_format
    fmt_str = FACET_TO_ENDNOTE_TYPE[fmt] || "Generic"
    fmt_str = "Electronic Book" if fmt == "Book" && export_online?

    text = +"%0 #{fmt_str}\n"

    export_languages.each { |la| text << "%G #{la}\n" }

    contributors = export_contributors || {}
    primary_authors = contributors[:primary_authors] || []
    secondary_authors = contributors[:secondary_authors] || []
    if primary_authors.present?
      first_author = primary_authors.first.to_s
      first_author = "#{first_author} " unless first_author.end_with?(" ")
      text << "%A #{first_author}\n"
      (primary_authors.drop(1) + secondary_authors).each do |author|
        value = author.to_s
        value = "#{value} " unless value.end_with?(" ")
        text << "%E #{value}\n"
      end
    elsif secondary_authors.present?
      secondary_authors.each do |author|
        value = author.to_s
        value = "#{value} " unless value.end_with?(" ")
        text << "%E #{value}\n"
      end
    end

    export_isbns.each { |isbn| text << "%@ #{isbn.strip}\n" }
    export_issns.each { |issn| text << "%@ #{issn.strip}\n" }

    title = export_title(separator: " ")
    if title.present?
      title = "#{title} " unless title.end_with?(" ")
      text << "%T #{title}\n"
    end

    edition = export_edition
    text << "%7 #{edition}\n" if edition.present?

    pub_data = export_publication_data || {}
    place = pub_data[:place]
    pname = pub_data[:publisher]
    pdate = pub_data[:date]

    if fmt_str == "Thesis"
      th = export_thesis_info
      if th.present?
        pname = th[:inst].to_s if th[:inst].present?
        pdate = th[:date].to_s if th[:date].present?
        thtype = th[:type].to_s
        text << "%9 #{thtype}\n" if thtype.present?
      end
    end

    text << "%I #{pname}\n" if pname.present?
    text << "%C #{place}\n" if place.present?
    text << "%D #{pdate}\n" if pdate.present?

    doi = export_doi
    text << "%R #{doi}\n" if doi.present?

    ul = export_access_url
    text << "%U #{ul}\n" if ul.present?

    where = export_holdings || []
    text << "%L #{where.join('//')}\n" unless where.blank? || where.join("").blank?

    catalog_url = export_catalog_url
    text << "%Z #{catalog_url}\n" if catalog_url.present?

    text = generate_en_keywords(text)
    # add a blank line to separate from possible next.
    text << "\n"

    text
  end

  def generate_en_keywords(text)
    export_keywords.each { |k| text << "%K #{k}\n" unless k.blank? }
    text
  end
end

# EXAMPLE EXPORT
# %0 Electronic Book
# %G English
# %A Van Laer, Rebecca
# %@ 9798765114650
# %@ 9798765114643
# %@
# %@
# %T Cat
# %7 1st edition
# %I Bloomsbury Academic
# %C New York
# %D 2025
# %R 10.5040/9798765114650
# %U https://search.ebscohost.com/login.aspx?direct=true&scope=site&db=nlebk&db=nlabk&AN=4278375
# %Z http://catalog.library.cornell.edu/catalog/17230874
# %K Cats Social aspects.
#   %K Human-animal relationships.

# documentation --
#https://www.citavi.com/sub/manual5/en/importing_an_endnote_tagged_file.html
# Importing an EndNote Tagged File
#
# Many web-based databases support direct export to Citavi. See Importing References in a Standard Format.
# If you have an EndNote tagged file (with the .enw file name extension) on your computer already, double-click it to start the import or drag it into the navigation pane in the Reference Editor.
# The reference types supported in EndNote Tagged format differ to some degree from the ones available in Citavi. This overview shows the mapping of reference types when importing from EndNote Tagged format:
#
# EndNote Tagged Reference Type
# %0 Ancient Text
# %0 Artwork
# %0 Audiovisual Material
# %0 Bill
# %0 Book
# %0 Book Section
# %0 Case
# %0 Chart or Table
# %0 Classical Work
# %0 Computer Program
# %0 Conference Paper
# %0 Conference Proceedings
# %0 Dictionary
# %0 Edited Book
# %0 Electronic Article
# %0 Electronic Book
# %0 Electronic Source
# %0 Encyclopedia
# %0 Equation
# %0 Figure
# %0 Film or Broadcast
# %0 Generic
# %0 Government Document
# Report or gray literature
# %0 Grant
# %0 Hearing
# %0 Journal Article
# Journal article
# %0 Legal Rule or Regulation
# Statute or regulation
# %0 Magazine Article
# Journal article
# %0 Manuscript
# %0 Map
# %0 Newspaper Article
# %0 Online Database
# %0 Online Multimedia
# %0 Patent
# %0 Personal Communication
# %0 Report
# %0 Statute
# %0 Thesis
# %0 Unpublished Work
# %0 Web Page
# %0 Unused 1
# %0 Unused 2
# %0 Unused 3
# ############Field Mapping
# When you import an EndNote Tagged file, Citavi uses various field mappings depending on the reference type. An EndNote Tagged file supports the following fields:
# %A Author
# %B Secondary Title (of a Book or Conference Name)
# %C Place Published
# %D Year
# %E Editor /Secondary Author
# %F Label
# %G Language
# %H Translated Author
# %I Publisher
# %J Secondary Title (Journal Name)
# %K Keywords
# %L Call Number
# %M Accession Number
# %N Number (Issue)
# %P Pages
# %Q Translated Title
# %R Electronic Resource Number
# %S Tertiary Title
# %T Title
# %U URL
# %V Volume
# %X Abstract
# %Y Tertiary Author
# %Z Notes
# %0 Reference Type
# %6 Number of Volumes
# %7 Edition
# %8 Date
# %9 Type of Work
# %? Subsidiary Author
# %@ ISBN/ISSN
# %( Original Publication
# %> Link to PDF
# %[ Access Date
