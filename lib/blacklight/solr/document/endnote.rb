# This module registers the Endnote tagged export format with the system so that we
# can offer export options for Mendeley and Zotero.
module Blacklight::Solr::Document::Endnote

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Solr::Document::Endnote.register_export_formats( document )
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

  def export_as_endnote()
    end_note_format = {
      "100.a" => "%A" ,
      "700.a" => "%E" ,
      "440.a" => "%J" ,
      "020.a" => "%@" ,
      "022.a" => "%@" ,
      "245.a,245.b" => "%T" ,
      "250.a" => "%7" 
    }
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    marc_obj = to_marc
    # TODO. This should be rewritten to guess
    # from actual Marc instead, probably.
    fmt_str = 'Generic'
    text = ''
    fmt = self['format'].first
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} fmt #{fmt.inspect}"
    if (FACET_TO_ENDNOTE_TYPE.keys.include?(fmt))
      fmt_str = FACET_TO_ENDNOTE_TYPE[fmt]
     end
    if  fmt == 'Book'  && self['online'] && self['online'].first == 'Online'
      fmt_str = 'Electronic Book'
    end
    ty = fmt_str
    text << "%0 #{ fmt_str }\n"
    # If there is some reliable way of getting the language of a record we can add it here
    #text << "%G #{record['language'].first}\n"
    if !self["language_facet"].blank?
       self["language_facet"].map{|la|  text += "%G #{la}\n" }
    end
    # #marc field is key, value is tag target
    end_note_format.each do |key,etag|
      Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} key,etag #{key},#{etag}")
      values = key.split(",")
      first_value = values[0].split('.')
      if values.length > 1
        second_value = values[1].split('.')
      else
        second_value = []
      end
      
      if marc_obj[first_value[0].to_s]
        marc_obj.find_all{|f| (first_value[0].to_s) === f.tag}.each do |field|
          if field[first_value[1]].to_s or field[second_value[1]].to_s
            text << "#{etag.gsub('_','')}"
            if field[first_value[1]].to_s
              text << " #{clean_end_punctuation(field[first_value[1]].to_s)}"
            end
            if field[second_value[1]].to_s
              text << " #{clean_end_punctuation(field[second_value[1]].to_s)}"
            end
            text << "\n"
          end
        end
      end
    end
    #"260.a" => "%C" ,
    #"264.a" => "%C" ,
    #"260.b" => "%I" ,
    #"264.b" => "%I" ,
    # publisher, and place. 
    pub_data = setup_pub_info(to_marc) # This function combines publisher and place
    place = ''
    pname = ''
    if !pub_data.nil?
      place, publisher = pub_data.split(':')
      pname = "#{publisher.strip!}" unless publisher.nil?
      # publication place
    end
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} ty #{ty.inspect}"
    #"264.c" => "%D" ,
    #"260.c" => "%D" ,
    pdate = setup_pub_date(to_marc) 
    if ty == 'Thesis'
      th = setup_thesis_info(to_marc)
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} th #{th.inspect}"
      pname = th[:inst].to_s
      pdate = th[:date].to_s unless th[:date].blank?
      thtype = th[:type].to_s
      text << "%9 #{thtype}\n" unless  thtype.blank? 
    end
    text << "%I #{pname}\n" unless  pname.blank? 
    text << "%C #{place}\n" unless  place.blank? 
    text << "%D #{pdate}\n" unless  pdate.blank? 
    # "024.a" => "%R" ,
    doi = setup_doi(to_marc)
    text << "%R #{doi}\n" unless  doi.blank? 
    if !self['url_access_display'].blank?
       ul = self['url_access_display'].first.split('|').first
       ul.sub!('http://proxy.library.cornell.edu/login?url=','')
       ul.sub!('http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=','')
    end
    #"856.u" => "%U" ,
    text << "%U #{ul}\n"  unless ul.blank?
    where = setup_holdings_info(to_marc)
    text << "%L  #{where.join('//')}\n"  unless where.blank? or where.join("").blank?
    text += "%Z http://newcatalog.library.cornell.edu/catalog/#{id}\n"
    text = generate_en_keywords(text,ty)
    # add a blank line to separate from possible next.
    text << "\n"  
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} endnote export = #{text}")
    text
  end

  def generate_en_keywords(text,ty)
    kw =   setup_kw_info(to_marc)
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} keywo    rds = #{kw.inspect}"
    kw.each do |k|
          text += "%K #{k}\n"   unless k.blank?
    end unless kw.blank?
    text 
  end

#Examples
#%0  Book
#%A  Geoffrey Chaucer
#%D  1957
#%T  The Works of Geoffrey Chaucer
#%E  F. N. Robinson
#%I   Houghton
#%C  Boston
#%N  2nd
# 
# %0  Journal Article
# %A  Herbert H. Clark
# %D  1982
# %T  Hearers and Speech Acts
# %B  Language
# %V  58
# %P  332-373
#  
#  %0  Thesis
#  %A  Cantucci, Elena
#  %T  Permian strata in South-East Asia
#  %D  1990
#  %I   University of California, Berkeley
#  %9  Dissertation
#

end

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
