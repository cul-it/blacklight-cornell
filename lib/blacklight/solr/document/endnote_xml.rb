# This module registers the ENDNOTE XML export format with the system so that we
# can offer options for Mendeley,Zotero, and Endnote
module Blacklight::Solr::Document::Endnote_xml

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Solr::Document::Endnote_xml.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:endnote_xml, "application/endnote+xml")
  end

  # Endnote Import Format. See the EndNote User Guide at:
  # http://www.endnote.com/support/enx3man-terms-win.asp
  # Chapter 7: Importing Reference Data into EndNote / Creating a Tagged “EndNote Import” File
  #
  # Note: This code is copied from what used to be in the previous version
  # in ApplicationHelper#render_to_endnote.  It does NOT produce very good
  # endnote import format; the %0 is likely to be entirely illegal, the
  # rest of the data is barely correct but messy. TODO, a new version of this,
  # or better yet just an export_as_ris instead, which will be more general
  # purpose. 
  # I reversed the sense of end_note_format table -- to allow multiple fields to map to
  # same endnote field. (es287@cornell.edu)
 
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
# these values might actually depend on how you have configured Endnote (@!#???)
# # I don't know how to figure this out except by trial and error.
# I exported records from endnote X8 to determine these.
#
FACET_TO_ENDNOTE_NUMERIC_VALUE =  { 
  "Audiovisual Material"=>"3", 
  "Book"=>"6", 
  "Computer Program"=>"9",
  "Film or Broadcast"=>"21", 
  "Manuscript" => "36", 
  "Map" => "20", 
  "Music" => "61", 
  "Online Database" => "45",
  "Thesis" => "32", 
}
# the xml format is defined here, in attached zip file:
# http://kbportal.thomson.com/display/2/index.aspx?tab=browse&c=&cpc=&cid=&cat=&catURL=&r=0.4727451
# top level elements:
# <!ELEMENT xml (records)>
# <!ELEMENT records (record+)>
# <!ELEMENT record (database?, source-app?, rec-number?, foreign-keys?, ref-type?, contributors?, auth-address?, auth-affiliaton?, titles?, periodical?, pages?, volume?, number?, issue?, secondary-volume?, secondary-issue?, num-vols?, edition?, section?, reprint-edition?, reprint-status?, keywords?, dates?, pub-location?, publisher?, orig-pub?, isbn?, accession-num?, call-num?, report-id?, coden?, electronic-resource-num?, abstract?, label?, image?, caption?, notes?, research-notes?, work-type?, reviewed-item?, availability?, remote-source?, meeting-place?, work-location?, work-extent?, pack-method?, size?, repro-ratio?, remote-database-name?, remote-database-provider?, language?, urls?, access-date?, modified-date?, custom1?, custom2?, custom3?, custom4?, custom5?, custom6?, custom7?, misc1?, misc2?, misc3?)>
# Note the order is required for validation, but may not be enforced by apps.
# among other things, the values for ref-type, and for role on the author element are not defined here.
  def export_as_endnote_xml()
    title = "#{clean_end_punctuation(setup_title_info(to_marc))}"
    fmt = self['format'].first
    num_ty = "0";
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{fmt.inspect}"
    ty = "Book"
    if (FACET_TO_ENDNOTE_TYPE.keys.include?(fmt))
      ty = FACET_TO_ENDNOTE_TYPE[fmt]
     end
    if (FACET_TO_ENDNOTE_NUMERIC_VALUE.keys.include?(ty))
      num_ty = FACET_TO_ENDNOTE_NUMERIC_VALUE[ty]
    end
    builder = Builder::XmlMarkup.new(:indent => 2,:margin => 4)
    builder.tag!("xml") do
      builder.records() do
        builder.record() do
          builder.database("MyLibrary") 
          builder.tag!("source-app","Cornell University Library","name" => "CULIB")
          builder.tag!("ref-type",num_ty,"name" => ty) 
          generate_enx_contributors(builder,ty)
          builder.titles() do 
            builder.title(title)  
          end
          generate_enx_edition(builder,ty)
          generate_enx_keywords(builder,ty)
          generate_enx_dates(builder,ty)
          generate_enx_location(builder,ty)
          generate_enx_publisher(builder,ty)
          generate_enx_isbn(builder,ty)
          generate_enx_callnum(builder,ty)
          generate_enx_doi(builder,ty)
          generate_enx_abstract(builder,ty)
          generate_enx_notes(builder,ty)
          generate_enx_work_type(builder,ty)
          generate_enx_language(builder,ty)
          generate_enx_urls(builder,ty)
        end
      end
    end
    text2 = builder.target!
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} endnote xml text = #{text2}"
    text2
  end
#<work-type>Ph.D.dissertation</work-type>
  def generate_enx_work_type(bld,ty)
    if ty == 'Thesis'
      thdata =   setup_thesis_info(to_marc)
      bld.tag!("work-type",thdata[:type].to_s) 
    end
  end

#
#nt =   setup_notes_info(to_marc)
#131     nt.each do |n|
#132       output +=  "N1  - #{n}" + "\n"
#133     end
#
  def generate_enx_notes(bld,ty)
    nt =   setup_notes_info(to_marc)
    nt <<  "http://newcatalog.library.cornell.edu/catalog/#{id}\n"
    bld.notes(nt.join(" ")) unless nt.blank? or nt.join("").blank?
  end

  def generate_enx_edition(bld,ty)
     et =  setup_edition(to_marc)
     bld.edition(et) unless et.blank?
  end

  def generate_enx_callnum(bld,ty)
    where = setup_holdings_info(bld)
    bld.tag!("call-num", where.join("//")) unless where.blank? or where.join("").blank?
  end

  def generate_enx_keywords(bld,ty)
    kw =   setup_kw_info(to_marc)
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} keywords = #{kw.inspect}"
    bld.keywords do
      kw.each do |k|
          bld.keyword(k) unless k.empty?
      end
    end unless kw.blank?
  end

  def generate_enx_abstract(bld,ty)
    k = setup_abst_info(to_marc)
    bld.abstract(k.join(' ')) unless k.blank?
  end
  def generate_enx_urls(bld,ty)
    if !self['url_access_display'].blank?
      ul = self['url_access_display'].first.split('|').first
      ul.sub!('http://proxy.library.cornell.edu/login?url=','')
      ul.sub!('http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=','')
    end
    bld.urls() { bld.tag!("web-urls") { bld.url(ul)}}  unless ul.blank?
  end

  def generate_enx_language(bld,ty)
    if !self["language_facet"].blank?
      self["language_facet"].map{|la|  bld.language(la)
      }
    end
  end

 #<electronic-resource-num>10.1007/978-3-319-27177-4</electronic-resource-num>
  def generate_enx_doi(bld,ty)
     doi = setup_doi(to_marc)
     bld.tag!("electronic-resource-num",doi) unless doi.blank?
  end

  def generate_enx_isbn(bld,ty)
    isbns = setup_isbn_info(to_marc) 
    bld.isbn(isbns.join(" ; "))   unless isbns.blank?
  end

  def generate_enx_location(bld,ty)
    # publisher
    pub_data = setup_pub_info(to_marc) # This function combines publisher and place
    place = ''
    pname = ''
    if !pub_data.nil?
      place, publisher = pub_data.split(':')
      pname = "#{publisher.strip!}" unless publisher.nil?
      bld.tag!("pub-location",place)
    end
  end
  def generate_enx_publisher(bld,ty)
    # publisher
    pub_data = setup_pub_info(to_marc) # This function combines publisher and place
    place = ''
    pname = ''
    if !pub_data.nil?
      place, publisher = pub_data.split(':')
      pname = publisher
      pname = "#{publisher.strip!}" unless publisher.nil?
    end
    if ty == 'Thesis' and pname.blank?
      th = setup_thesis_info(to_marc)
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} th #{th.inspect}"
      pname = th[:inst].to_s
    end
    bld.publisher(pname) unless pname.blank?
  end

# example: <dates>
#  <year>1985</year>
#  <pub-dates>
#    <date>1985</date>
#  </pub-dates>
#  </dates>
#
  def generate_enx_dates(bld,ty)
    yr  = "#{setup_pub_date(to_marc)}"
    if !yr.empty?
      bld.dates() do
        bld.year(yr) 
        bld.tag!("pub-dates") do
          bld.date(yr) 
        end
      end
    end
  end

  def generate_enx_contributors(bld,ty)
    authors = get_all_authors(to_marc)
    relators =  get_contrib_roles(to_marc)
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} relators = #{relators.inspect}"
    primary_authors = authors[:primary_authors]
    if primary_authors.blank? and !authors[:primary_corporate_authors].blank?
      primary_authors = authors[:primary_corporate_authors]
    end
    secondary_authors = authors[:secondary_authors]
    meeting_authors = authors[:meeting_authors]
    #secondary_authors.delete_if { | a | relators.has_key?(a) and !relators[a].blank? }
    #primary_authors.delete_if { | a | relators.has_key?(a) and !relators[a].blank? }
    editors = authors[:editors]
    pa = primary_authors.blank? ? secondary_authors : primary_authors
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} endnote pa = #{pa.inspect}"
    bld.contributors() do 
      if !pa.blank?
        bld.authors() do 
          pa.map { |a| bld.author(a) } 
        end
      end
      if !editors.blank?
        bld.tag!("tertiary-authors") do 
          editors.map { |a| bld.author(a) } 
        end
      end
     
    end
  end




end
