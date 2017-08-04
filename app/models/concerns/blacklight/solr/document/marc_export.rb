# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
# Written for use with Blacklight::Solr::Document::Marc, but you can use
# it for your own custom Blacklight document Marc extension too -- just
# include this module in any document extension (or any other class)
# that provides a #to_marc returning a ruby-marc object.  This module will add
# in export_as translation methods for a variety of formats. 
module Blacklight::Solr::Document::MarcExport
  
  def self.register_export_formats(document)
    document.will_export_as(:xml)
    document.will_export_as(:marc, "application/marc")
    # marcxml content type: 
    # http://tools.ietf.org/html/draft-denenberg-mods-etc-media-types-00
    document.will_export_as(:marcxml, "application/marcxml+xml")
    document.will_export_as(:openurl_ctx_kev, "application/x-openurl-ctx-kev")
    document.will_export_as(:refworks_marc_txt, "text/plain")
    document.will_export_as(:endnote, "application/x-endnote-refer")
  end


  def export_as_marc
    to_marc.to_marc
  end

  def export_as_marcxml
    to_marc.to_xml.to_s
  end
  alias_method :export_as_xml, :export_as_marcxml
  
  
  # TODO This exporting as formatted citation thing should be re-thought
  # redesigned at some point to be more general purpose, but this
  # is in-line with what we had before, but at least now attached
  # to the document extension where it belongs. 
  def export_as_apa_citation_txt
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    citeproc_citation( to_marc,'apa')
    #apa_citation( to_marc )
  end
  
  def export_as_mla_citation_txt
    citeproc_citation( to_marc,'modern-language-association')
    #mla_citation( to_marc )
  end

  def old_xxx_export_as_mla8_citation_txt
    mla8_citation( to_marc )
  end

    #cp  = CiteProc::Processor.new style: 'modern-language-association-8th-edition', format: 'html'
  def export_as_mla8_citation_txt
    citeproc_citation( to_marc,'modern-language-association-8th-edition')
  end

  def export_as_mla8_proc_citation_txt
    citeproc_citation( to_marc )
  end
  
  def export_as_chicago_citation_txt
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    citeproc_citation( to_marc,'chicago-fullnote-bibliography')
    #chicago_citation( to_marc )
  end

  # Exports as an OpenURL KEV (key-encoded value) query string.
  # For use to create COinS, among other things. COinS are
  # for Zotero, among other things. TODO: This is wierd and fragile
  # code, it should use ruby OpenURL gem instead to work a lot
  # more sensibly. The "format" argument was in the old marc.marc.to_zotero
  # call, but didn't neccesarily do what it thought it did anyway. Left in
  # for now for backwards compatibilty, but should be replaced by
  # just ruby OpenURL. 
  def export_as_openurl_ctx_kev(format = nil)  
    title = to_marc.find{|field| field.tag == '245'}
    author = to_marc.find{|field| field.tag == '100'}
    corp_author = to_marc.find{|field| field.tag == '110'}
    publisher_info = to_marc.find{|field| field.tag == '260'}
    edition = to_marc.find{|field| field.tag == '250'}
    isbn = to_marc.find{|field| field.tag == '020'}
    issn = to_marc.find{|field| field.tag == '022'}
    unless format.nil?
      format.is_a?(Array) ? format = format[0].downcase.strip : format = format.downcase.strip
    end
      export_text = ""
      if format == 'book'
        export_text << "ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=book&amp;"
        export_text << "rft.btitle=#{(title.nil? or title['a'].nil?) ? "" : CGI::escape(title['a'])}+#{(title.nil? or title['b'].nil?) ? "" : CGI::escape(title['b'])}&amp;"
        export_text << "rft.title=#{(title.nil? or title['a'].nil?) ? "" : CGI::escape(title['a'])}+#{(title.nil? or title['b'].nil?) ? "" : CGI::escape(title['b'])}&amp;"
        export_text << "rft.au=#{(author.nil? or author['a'].nil?) ? "" : CGI::escape(author['a'])}&amp;"
        export_text << "rft.aucorp=#{CGI::escape(corp_author['a']) if corp_author['a']}+#{CGI::escape(corp_author['b']) if corp_author['b']}&amp;" unless corp_author.blank?
        export_text << "rft.date=#{(publisher_info.nil? or publisher_info['c'].nil?) ? "" : CGI::escape(publisher_info['c'])}&amp;"
        export_text << "rft.place=#{(publisher_info.nil? or publisher_info['a'].nil?) ? "" : CGI::escape(publisher_info['a'])}&amp;"
        export_text << "rft.pub=#{(publisher_info.nil? or publisher_info['b'].nil?) ? "" : CGI::escape(publisher_info['b'])}&amp;"
        export_text << "rft.edition=#{(edition.nil? or edition['a'].nil?) ? "" : CGI::escape(edition['a'])}&amp;"
        export_text << "rft.isbn=#{(isbn.nil? or isbn['a'].nil?) ? "" : isbn['a']}"
      elsif (format =~ /journal/i) # checking using include because institutions may use formats like Journal or Journal/Magazine
        export_text << "ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=article&amp;"
        export_text << "rft.title=#{(title.nil? or title['a'].nil?) ? "" : CGI::escape(title['a'])}+#{(title.nil? or title['b'].nil?) ? "" : CGI::escape(title['b'])}&amp;"
        export_text << "rft.atitle=#{(title.nil? or title['a'].nil?) ? "" : CGI::escape(title['a'])}+#{(title.nil? or title['b'].nil?) ? "" : CGI::escape(title['b'])}&amp;"
        export_text << "rft.aucorp=#{CGI::escape(corp_author['a']) if corp_author['a']}+#{CGI::escape(corp_author['b']) if corp_author['b']}&amp;" unless corp_author.blank?
        export_text << "rft.date=#{(publisher_info.nil? or publisher_info['c'].nil?) ? "" : CGI::escape(publisher_info['c'])}&amp;"
        export_text << "rft.issn=#{(issn.nil? or issn['a'].nil?) ? "" : issn['a']}"
      else
         export_text << "ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;"
         export_text << "rft.title=" + ((title.nil? or title['a'].nil?) ? "" : CGI::escape(title['a']))
         export_text <<  ((title.nil? or title['b'].nil?) ? "" : CGI.escape(" ") + CGI::escape(title['b']))
         export_text << "&amp;rft.creator=" + ((author.nil? or author['a'].nil?) ? "" : CGI::escape(author['a']))
         export_text << "&amp;rft.aucorp=#{CGI::escape(corp_author['a']) if corp_author['a']}+#{CGI::escape(corp_author['b']) if corp_author['b']}" unless corp_author.blank?
         export_text << "&amp;rft.date=" + ((publisher_info.nil? or publisher_info['c'].nil?) ? "" : CGI::escape(publisher_info['c']))
         export_text << "&amp;rft.place=" + ((publisher_info.nil? or publisher_info['a'].nil?) ? "" : CGI::escape(publisher_info['a']))
         export_text << "&amp;rft.pub=" + ((publisher_info.nil? or publisher_info['b'].nil?) ? "" : CGI::escape(publisher_info['b']))
         export_text << "&amp;rft.format=" + (format.nil? ? "" : CGI::escape(format))
     end
     export_text.html_safe unless export_text.blank?
  end


  # This format used to be called 'refworks', which wasn't really
  # accurate, sounds more like 'refworks tagged format'. Which this
  # is not, it's instead some weird under-documented Refworks 
  # proprietary marc-ish in text/plain format. See
  # http://robotlibrarian.billdueber.com/sending-marcish-data-to-refworks/
  def export_as_refworks_marc_txt
    fields = to_marc.find_all { |f| ('000'..'999') === f.tag }
    text = "LEADER #{to_marc.leader}"
    fields.each do |field|
    unless ["940","999"].include?(field.tag)
      if field.is_a?(MARC::ControlField)
        text << "#{field.tag}    #{field.value}\n"
      else
        text << "#{field.tag} "
        text << (field.indicator1 ? field.indicator1 : " ")
        text << (field.indicator2 ? field.indicator2 : " ")
        text << " "
          field.each {|s| s.code == 'a' ? text << "#{s.value}" : text << " |#{s.code}#{s.value}"}
        text << "\n"
       end
        end
    end

    # As of 11 May 2010, Refworks has a problem with UTF-8 if it's decomposed,
    # it seems to want C form normalization, although RefWorks support
    # couldn't tell me that. -jrochkind
    text = ActiveSupport::Multibyte::Unicode.normalize(text, :c)
    
    return text
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
  def export_as_endnote()
    end_note_format = {
      "%A" => "100.a",
      "%C" => "260.a",
      "%D" => "260.c",
      "%E" => "700.a",
      "%I" => "260.b",
      "%J" => "440.a",
      "%@" => "020.a",
      "%_@" => "022.a",
      "%T" => "245.a,245.b",
      "%U" => "856.u",
      "%7" => "250.a"
    }
    marc_obj = to_marc
    # TODO. This should be rewritten to guess
    # from actual Marc instead, probably.
    format_str = 'Generic'
    
    text = ''
    text << "%0 #{ format_str }\n"
    # If there is some reliable way of getting the language of a record we can add it here
    #text << "%G #{record['language'].first}\n"
    end_note_format.each do |key,value|
      values = value.split(",")
      first_value = values[0].split('.')
      if values.length > 1
        second_value = values[1].split('.')
      else
        second_value = []
      end
      
      if marc_obj[first_value[0].to_s]
        marc_obj.find_all{|f| (first_value[0].to_s) === f.tag}.each do |field|
          if field[first_value[1]].to_s or field[second_value[1]].to_s
            text << "#{key.gsub('_','')}"
            if field[first_value[1]].to_s
              text << " #{field[first_value[1]].to_s}"
            end
            if field[second_value[1]].to_s
              text << " #{field[second_value[1]].to_s}"
            end
            text << "\n"
          end
        end
      end
    end
    text
  end

  protected
# see http://www.chicagomanualofstyle.org/16/ch14/ch14_sec018.html 
# examples:
# Chicago 16th ed.
# Single author.
# Pollan, Michael. The Omnivore’s Dilemma: A Natural History of Four Meals. New York: Penguin, 2006.
# Single editor.
# Greenberg, Joel, ed. Of Prairie, Woods, and Water: Two Centuries of Chicago Nature Writing. Chicago: University of Chicago Press, 2008.
 def chicago_citation(marc)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    authors = get_all_authors(marc)
    author_text = ""

    # If there are secondary (i.e. from 700 fields) authors, add them to
    # primary authors only if there are no corporate, meeting, primary authors
    if !authors[:primary_authors].blank?
      authors[:primary_authors] += authors[:secondary_authors] unless authors[:secondary_authors].blank?
    elsif !authors[:secondary_authors].blank?
      authors[:primary_authors] = authors[:secondary_authors] if (authors[:corporate_authors].blank? or  authors[:meeting_authors].blank?)
    end

    # Work with primary authors first
    if !authors[:primary_authors].blank?

      # Handle differently if there are more then 10 authors (use et al.)
      if authors[:primary_authors].length > 10
        authors[:primary_authors].each_with_index do |author,index|
          # For the first 7 authors...
          if index < 7
            if index == 0
              author_text << "#{author}"
              if author.ends_with?(",")
                author_text << " "
              else
                author_text << ", "
              end
            else
              author_text << "#{name_reverse(author)}, "
            end
          end
        end
        author_text << " et al."
      # If there are at least 2 primary authors
      elsif authors[:primary_authors].length > 1
        authors[:primary_authors].each_with_index do |author,index|
          if index == 0
            author_text << "#{author}"
            if author.ends_with?(",")
              author_text << " "
            else
              author_text << ", "
            end
          elsif index + 1 == authors[:primary_authors].length
            author_text << "and #{name_reverse(author)}."
          else
            author_text << "#{name_reverse(author)}, "
          end
        end
      else
        # Only 1 primary author
        author_text << authors[:primary_authors].first + '.'
      end
    elsif !authors[:corporate_authors].blank? && authors[:editors].blank?
      # This is a simplistic assumption that the first corp author entry
      # is the only one of interest (and it's not too long)
      author_text << authors[:corporate_authors].first + '.'
    elsif !authors[:meeting_authors].blank? && authors[:editors].blank?
      # This is a simplistic assumption that the first corp author entry
      # is the only one of interest (and it's not too long)
      author_text << authors[:meeting_authors].first + '.'
    else
      # Secondary authors: translators, editors, compilers
      temp_authors = []
      authors[:translators].each do |translator|
        temp_authors << [translator, "trans"]
      end
      authors[:editors].each do |editor|
        temp_authors << [editor, "ed"]
      end
      authors[:compilers].each do |compiler|
        temp_authors << [compiler, "comp"]
      end
      Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} temp_authors = #{temp_authors.inspect}")

      unless temp_authors.blank?
        if temp_authors.length > 10
          temp_authors.each_with_index do |author,index|
            if index < 7
              author_text << "#{author.first} "
            end
          end
          author_text << " et al.,#{temp_authors.first.last}s. "
        elsif temp_authors.length > 1
          temp_authors.each_with_index do |author,index|
            if index == 0
              author_text << "#{author.first} "
            elsif index + 1 == temp_authors.length
              author_text << "and #{name_reverse(author.first)}, #{author.last}s. "
            else
              author_text << "#{name_reverse(author.first)}, "
            end
          end
        else
          author_text << "#{temp_authors.first.first}, #{temp_authors.first.last}. "
        end
      end
    end
    title = ""
    additional_title = ""
    section_title = ""
    if marc["245"] and (marc["245"]["a"] or marc["245"]["b"])
      title << citation_title(clean_end_punctuation(marc["245"]["a"]).strip) if marc["245"]["a"]
      title << ": #{citation_title(clean_end_punctuation(marc["245"]["b"]).strip)}" if marc["245"]["b"]
    end
    if marc["245"] and (marc["245"]["n"] or marc["245"]["p"])
      section_title << citation_title(clean_end_punctuation(marc["245"]["n"])) if marc["245"]["n"]
      if marc["245"]["p"]
        section_title << ", <i>#{citation_title(clean_end_punctuation(marc["245"]["p"]))}.</i>"
      elsif marc["245"]["n"]
        section_title << "."
      end
    end

    if !authors[:primary_authors].blank? and (!authors[:translators].blank? or !authors[:editors].blank? or !authors[:compilers].blank?)
        additional_title << "Translated by #{authors[:translators].collect{|name| name_reverse(name)}.join(" and ")}. " unless authors[:translators].blank?
        additional_title << "Edited by #{authors[:editors].collect{|name| name_reverse(name)}.join(" and ")}. " unless authors[:editors].blank?
        additional_title << "Compiled by #{authors[:compilers].collect{|name| name_reverse(name)}.join(" and ")}. " unless authors[:compilers].blank?
    end

    edition = ""
    edition << setup_edition(marc) unless setup_edition(marc).nil?

    pub_info = ""
    if marc["260"] and (marc["260"]["a"] or marc["260"]["b"])
      pub_info << clean_end_punctuation(marc["260"]["a"]).strip if marc["260"]["a"]
      pub_info << ": #{clean_end_punctuation(marc["260"]["b"]).strip}" if marc["260"]["b"]
      pub_info << ", #{setup_pub_date(marc)}" if marc["260"]["c"]
    elsif marc["264"] and (marc["264"]["a"] or marc["264"]["b"])
      pub_info << clean_end_punctuation(marc["264"]["a"]).strip if marc["264"]["a"]
      pub_info << ": #{clean_end_punctuation(marc["264"]["b"]).strip}" if marc["264"]["b"]
      pub_info << ", #{setup_pub_date(marc)}" if marc["264"]["c"]
    elsif marc["502"] and marc["502"]["a"] # MARC 502 is the Dissertation Note.  This holds the correct pub info for these types of records.
      pub_info << marc["502"]["a"]
    elsif marc["502"] and (marc["502"]["b"] or marc["502"]["c"] or marc["502"]["d"]) #sometimes the dissertation note is encoded in pieces in the $b $c and $d sub fields instead of lumped into the $a
      pub_info << "#{marc["502"]["b"]}, #{marc["502"]["c"]}, #{clean_end_punctuation(marc["502"]["d"])}"
    end

    citation = ""
    citation << "#{author_text} " unless author_text.blank?
    citation << "<i>#{title}.</i> " unless title.blank?
    citation << "#{section_title} " unless section_title.blank?
    citation << "#{additional_title} " unless additional_title.blank?
    citation << "#{edition}" unless edition.blank?
    citation << "#{pub_info}." unless pub_info.blank?
    citation
  end



 
  # Main method for defining chicago style citation.  If we don't end up converting to using a citation formatting service
  # we should make this receive a semantic document and not MARC so we can use this with other formats.
  def xxx_chicago_citation(marc)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    authors = get_all_authors(marc)    
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors = #{authors.inspect}")
    author_text = ""
    unless authors[:primary_authors].blank?
      if authors[:primary_authors].length > 10
        authors[:primary_authors].each_with_index do |author,index|
          if index < 7
            if index == 0
              author_text << "#{author}"
              if author.ends_with?(",")
                author_text << " "
              else
                author_text << ", "
              end
            else
              author_text << "#{name_reverse(author)}, "
            end
          end
        end
        author_text << " et al."
      elsif authors[:primary_authors].length > 1
        authors[:primary_authors].each_with_index do |author,index|
          if index == 0
            author_text << "#{author}"
            if author.ends_with?(",")
              author_text << " "
            else
              author_text << ", "
            end
          elsif index + 1 == authors[:primary_authors].length
            author_text << "and #{name_reverse(author)}."
          else
            author_text << "#{name_reverse(author)}, "
          end 
        end
      else
        author_text << authors[:primary_authors].first
      end
    else
      temp_authors = []
      authors[:translators].each do |translator|
        temp_authors << [translator, "trans."]
      end
      authors[:editors].each do |editor|
        temp_authors << [editor, "ed."]
      end
      authors[:compilers].each do |compiler|
        temp_authors << [compiler, "comp."]
      end
      
      unless temp_authors.blank?
        if temp_authors.length > 10
          temp_authors.each_with_index do |author,index|
            if index < 7
              author_text << "#{author.first} #{author.last} "
            end
          end
          author_text << " et al."
        elsif temp_authors.length > 1
          temp_authors.each_with_index do |author,index|
            if index == 0
              author_text << "#{author.first} #{author.last}, "
            elsif index + 1 == temp_authors.length
              author_text << "and #{name_reverse(author.first)} #{author.last}"
            else
              author_text << "#{name_reverse(author.first)} #{author.last}, "
            end
          end
        else
          author_text << "#{temp_authors.first.first} #{temp_authors.first.last}"
        end
      end
    end
    title = ""
    additional_title = ""
    section_title = ""
    if marc["245"] and (marc["245"]["a"] or marc["245"]["b"])
      title << citation_title(clean_end_punctuation(marc["245"]["a"]).strip) if marc["245"]["a"]
      title << ": #{citation_title(clean_end_punctuation(marc["245"]["b"]).strip)}" if marc["245"]["b"]
    end
    if marc["245"] and (marc["245"]["n"] or marc["245"]["p"])
      section_title << citation_title(clean_end_punctuation(marc["245"]["n"])) if marc["245"]["n"]
      if marc["245"]["p"]
        section_title << ", <i>#{citation_title(clean_end_punctuation(marc["245"]["p"]))}.</i>"
      elsif marc["245"]["n"]
        section_title << "."
      end
    end
    
    if !authors[:primary_authors].blank? and (!authors[:translators].blank? or !authors[:editors].blank? or !authors[:compilers].blank?)
        additional_title << "Translated by #{authors[:translators].collect{|name| name_reverse(name)}.join(" and ")}. " unless authors[:translators].blank?
        additional_title << "Edited by #{authors[:editors].collect{|name| name_reverse(name)}.join(" and ")}. " unless authors[:editors].blank?
        additional_title << "Compiled by #{authors[:compilers].collect{|name| name_reverse(name)}.join(" and ")}. " unless authors[:compilers].blank?
    end
    
    edition = ""
    edition << setup_edition(marc) unless setup_edition(marc).nil?
    
    pub_info = ""
    if marc["260"] and (marc["260"]["a"] or marc["260"]["b"]) 
      pub_info << clean_end_punctuation(marc["260"]["a"]).strip if marc["260"]["a"]
      pub_info << ": #{clean_end_punctuation(marc["260"]["b"]).strip}" if marc["260"]["b"]
      pub_info << ", #{setup_pub_date(marc)}" if marc["260"]["c"]
    elsif marc["502"] and marc["502"]["a"] # MARC 502 is the Dissertation Note.  This holds the correct pub info for these types of records.
      pub_info << marc["502"]["a"]
    elsif marc["502"] and (marc["502"]["b"] or marc["502"]["c"] or marc["502"]["d"]) #sometimes the dissertation note is encoded in pieces in the $b $c and $d sub fields instead of lumped into the $a
      pub_info << "#{marc["502"]["b"]}, #{marc["502"]["c"]}, #{clean_end_punctuation(marc["502"]["d"])}"
    end
    
    citation = ""
    citation << "#{author_text} " unless author_text.blank?
    citation << "<i>#{title}.</i> " unless title.blank?
    citation << "#{section_title} " unless section_title.blank?
    citation << "#{additional_title} " unless additional_title.blank?
    citation << "#{edition} " unless edition.blank?
    citation << "#{pub_info}." unless pub_info.blank?
    citation
  end
  
  
  
  def citeproc_citation(record,csl)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} csl = #{csl.inspect}")
    cp  = CiteProc::Processor.new style: csl, format: 'html'
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} cp = #cp.inspect}")
    authors_final = []
    editors_final = []
    all_authors = get_all_authors(record)
      # If there are secondary (i.e. from 700 fields) authors, add them to
      # primary authors only if there are no corporate, meeting, primary authors
    if !all_authors[:primary_authors].blank?
      all_authors[:primary_authors] += all_authors[:secondary_authors] unless all_authors[:secondary_authors].blank?
    elsif !all_authors[:secondary_authors].blank?
      all_authors[:primary_authors] = all_authors[:secondary_authors] if (all_authors[:corporate_authors].blank? &&  all_authors[:meeting_authors].blank?)
    end
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} all_authors = #{all_authors.inspect}")
    authors = case
              when !all_authors[:primary_authors].blank?
               all_authors[:primary_authors]
              when !all_authors[:primary_corporate_authors].blank?
                all_authors[:primary_corporate_authors]
              when !all_authors[:meeting_authors].blank?
                all_authors[:meeting_authors]
              when !all_authors[:secondary_authors].blank?
                all_authors[:secondary_authors]
              when !all_authors[:secondary_corporate_authors].blank?
                all_authors[:secondary_corporate_authors]
              else
                []
    end
    editors  = case
              when !all_authors[:editors].blank?
                all_authors[:editors]
              else
                []
    end
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors = #{authors.inspect}")
    if !authors.blank?
      authors.each do |nam|
        if  nam.include?(',')
          family,given = nam.split(",")
          a =  CiteProc::Name.new(:family => family, :given => given)
        else
          b = nam.index('(').nil? ? nam : nam[0,nam.index('(')].rstrip 
          a =  CiteProc::Name.new(:literal => b)
        end
        authors_final << a
      end
    end
    if !editors.blank?
      editors.each do |nam|
        if  nam.include?(',')
          family,given = nam.split(",")
          a =  CiteProc::Name.new(:family => family, :given => given)
        else
          b = nam.index('(').nil? ? nam : nam[0,nam.index('(')].rstrip 
          a =  CiteProc::Name.new(:literal => b)
        end
        editors_final << a
      end
    end
    title = setup_title_info(record)
    issued =  setup_pub_date(record) unless setup_pub_date(record).nil?
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors_final = #{authors_final.inspect}")
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} title = #{title.inspect}")
    publisher = setup_pub_info_mla8(record) unless setup_pub_info_mla8(record).nil?
    publisher.squish! unless publisher.nil?
    publisher_place,dummy = setup_pub_info(record).split(':') unless setup_pub_info(record).nil?
    publisher_place.squish! unless publisher_place.nil?
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} publisher_place = #{publisher_place.inspect}")
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}dummy=#{dummy.inspect}")
    id = "id #{csl}"
    ul = ''
    if !self['url_access_display'].blank?
       ul = self['url_access_display'].first.split('|').first
       # might have proxy link -- http://proxy.library.cornell.edu/login?url=http://site.ebrary.com/lib/cornell/Top?id=11014930
       # or gateway link
       ul.sub!('http://proxy.library.cornell.edu/login?url=','')
       ul.sub!('http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=','')
    end
    edition_data = setup_edition(record)
    edition_final = edition_data.blank? ? ""  : edition_data
    item = CiteProc::Item.new(
      :id => id,
      :type => 'book',
      :title => title,
      :author => authors_final,
      :editor => editors_final,
      :issued => { 'literal' => issued },
      :edition => edition_final,
      :publisher => publisher ,
      :URL => ul,
      'publisher-place' => publisher_place 
    )
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} item=#{item.inspect}")
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} place=#{item.publisher_place.inspect}")
    cp << item
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} cp=#{cp.inspect}")
    #cp.options()[:style].titleize + "<br/>" + (cp.render :bibliography, id: id)[0]
    (cp.render :bibliography, id: id)[0]
    end

  def mla8_citation(record)

    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    text = ''
    authors_final = []
    
    #setup formatted author list
    #authors = get_author_list(record)
    all_authors = get_all_authors(record)
      # If there are secondary (i.e. from 700 fields) authors, add them to
      # primary authors only if there are no corporate, meeting, primary authors
    if !all_authors[:primary_authors].blank?
      all_authors[:primary_authors] += all_authors[:secondary_authors] unless all_authors[:secondary_authors].blank?
     elsif !all_authors[:secondary_authors].blank?
      all_authors[:primary_authors] = all_authors[:secondary_authors] if (all_authors[:corporate_authors].blank? &&  all_authors[:meeting_authors].blank?)
     end
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} all_authors = #{all_authors.inspect}")
    authors = case
              when !all_authors[:primary_authors].blank?
               all_authors[:primary_authors]
              when !all_authors[:primary_corporate_authors].blank?
                all_authors[:primary_corporate_authors]
              when !all_authors[:meeting_authors].blank?
                all_authors[:meeting_authors]
              when !all_authors[:secondary_authors].blank?
                all_authors[:secondary_authors]
              when !all_authors[:secondary_corporate_authors].blank?
                all_authors[:secondary_corporate_authors]
              else
                []
              end
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors = #{authors.inspect}")
    if !authors.blank?
    if authors.length < 4
      authors.each do |l|
        if l == authors.first #first
          authors_final.push(l)
        elsif l == authors.last #last
          authors_final.push(", and " + name_reverse(l) + ".")
        else #all others
          authors_final.push(", " + name_reverse(l))
        end
      end
      text += authors_final.join
      unless text.blank?
        if text[-1,1] != "."
          text += ". "
        else
          text += " "
        end
      end
    else
      text += authors.first + ", et al. "
    end
    end
    # setup title
    title = setup_title_info(record)
    if !title.nil?
      text += "<i>" + mla_citation_title(title) + "</i> "
    end

    # Edition
    edition_data = setup_edition(record)
    text += edition_data + " " unless edition_data.nil?
    
    # Publication
    text += setup_pub_info_mla8(record) + ", " unless setup_pub_info(record).nil?
    
    # Get Pub Date
    text += setup_pub_date(record) unless setup_pub_date(record).nil?
    if text[-1,1] != "."
      text += "." unless text.nil? or text.blank?
    end
    text
  end

  def mla_citation(record)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    text = ''
    authors_final = []
    
    #setup formatted author list
    #authors = get_author_list(record)
    all_authors = get_all_authors(record)
      # If there are secondary (i.e. from 700 fields) authors, add them to
      # primary authors only if there are no corporate, meeting, primary authors
    if !all_authors[:primary_authors].blank?
      all_authors[:primary_authors] += all_authors[:secondary_authors] unless all_authors[:secondary_authors].blank?
     elsif !all_authors[:secondary_authors].blank?
      all_authors[:primary_authors] = all_authors[:secondary_authors] if (all_authors[:corporate_authors].blank? &&  all_authors[:meeting_authors].blank?)
     end

    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} all_authors = #{all_authors.inspect}")
    authors = case
              when !all_authors[:primary_authors].blank?
               all_authors[:primary_authors]
              when !all_authors[:primary_corporate_authors].blank?
                all_authors[:primary_corporate_authors]
              when !all_authors[:meeting_authors].blank?
                all_authors[:meeting_authors]
              when !all_authors[:secondary_authors].blank?
                all_authors[:secondary_authors]
              when !all_authors[:secondary_corporate_authors].blank?
                all_authors[:secondary_corporate_authors]
              else
                []
              end
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors = #{authors.inspect}")
    if !authors.blank?
    if authors.length < 4
      authors.each do |l|
        if l == authors.first #first
          authors_final.push(l)
        elsif l == authors.last #last
          authors_final.push(", and " + name_reverse(l) + ".")
        else #all others
          authors_final.push(", " + name_reverse(l))
        end
      end
      text += authors_final.join
      unless text.blank?
        if text[-1,1] != "."
          text += ". "
        else
          text += " "
        end
      end
    else
      text += authors.first + ", et al. "
    end
    end
    # setup title
    title = setup_title_info(record)
    if !title.nil?
      text += "<i>" + mla_citation_title(title) + "</i> "
    end

    # Edition
    edition_data = setup_edition(record)
    text += edition_data + " " unless edition_data.nil?
    
    # Publication
    text += setup_pub_info(record) + ", " unless setup_pub_info(record).nil?
    
    # Get Pub Date
    text += setup_pub_date(record) unless setup_pub_date(record).nil?
    if text[-1,1] != "."
      text += "." unless text.nil? or text.blank?
    end
    text
  end

  def apa_citation(record)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    text = ''
    authors_list = []
    authors_list_final = []
    
    #setup formatted author list
    authors = apa_get_author_list(record)
    authors.each do |l|
      authors_list.push(abbreviate_name(l)) unless l.blank?
    end
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors = #{authors.inspect}")
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} authors_list = #{authors_list.inspect}")
    authors_list.each do |l|
      if l == authors_list.first #first
        authors_list_final.push(l.strip)
      elsif l == authors_list.last #last
        authors_list_final.push(", &amp; " + l.strip)
      else #all others
        authors_list_final.push(", " + l.strip)
      end
    end
    text += authors_list_final.join
    unless text.blank?
      if text[-1,1] != "."
        text += ". "
      else
        text += " "
      end
    end
    # Get Pub Date
    text += "(" + setup_pub_date(record) + "). " unless setup_pub_date(record).nil?
    
    # setup title info
    title = setup_title_info(record)
    text += "<i>" + title + "</i> " unless title.nil?
    
    # Edition
    edition_data = setup_edition(record)
    text += edition_data + " " unless edition_data.nil?
    
    # Publisher info
    text += setup_pub_info(record) unless setup_pub_info(record).nil?
    unless text.blank?
      if text[-1,1] != "."
        text += "."
      end
    end
    text
  end

  def setup_pub_info_mla8(record)
    text = ''
    pub_info_field = record.find{|f| f.tag == '260'}
    if pub_info_field.nil?
      pub_info_field = record.find{|f| f.tag == '264' && f.indicator2 == '1'}
    end
    if !pub_info_field.nil?
      b_pub_info = pub_info_field.find{|s| s.code == 'b'}
      a_pub_info = clean_end_punctuation(a_pub_info.value.strip) unless a_pub_info.nil?
      b_pub_info = b_pub_info.value.strip unless b_pub_info.nil?
      text += a_pub_info.strip unless a_pub_info.nil?
      if !a_pub_info.nil? and !b_pub_info.nil?
        text += ": "
      end
      text += b_pub_info.strip unless b_pub_info.nil?
    end
    #print STANDARD_INFO  + "text = #{text}"
    return nil if text.strip.blank?
    clean_end_punctuation(text.strip)
  end 
  def setup_pub_info(record)
    text = ''
    pub_info_field = record.find{|f| f.tag == '260'}
    if pub_info_field.nil?
      pub_info_field = record.find{|f| f.tag == '264' && f.indicator2 == '1'}
    end
    if !pub_info_field.nil?
      a_pub_info = pub_info_field.find{|s| s.code == 'a'}
      b_pub_info = pub_info_field.find{|s| s.code == 'b'}
      a_pub_info = clean_end_punctuation(a_pub_info.value.strip) unless a_pub_info.nil?
      b_pub_info = b_pub_info.value.strip unless b_pub_info.nil?
      text += a_pub_info.strip unless a_pub_info.nil?
      if !a_pub_info.nil? and !b_pub_info.nil?
        text += ": "
      end
      text += b_pub_info.strip unless b_pub_info.nil?
    end
    #print STANDARD_INFO  + "text = #{text}"
    return nil if text.strip.blank?
    clean_end_punctuation(text.strip)
  end

  def setup_pub_date(record)
    pub_date = record.find{|f| f.tag == '260'}
    if pub_date.nil?
      pub_date = record.find{|f| f.tag == '264' && f.indicator2 == '1'}
    end
    if !pub_date.nil?
      if pub_date.find{|s| s.code == 'c'}
        date_value = pub_date.find{|s| s.code == 'c'}.value
        if date_value.include? 'n.d.'
          date_value = 'n.d'
        elsif !date_value.gsub(/[^0-9]/, '')[0,4].blank?
          date_value = date_value.gsub(/[^0-9]/, '')[0,4]
        end
      end
      return nil if date_value.nil?
    end
    clean_end_punctuation(date_value) if date_value
  end
  # process 100,110,111 and 700, 710, 711
  # putting together role indicators.
  def get_contrib_roles(record)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    contributors = ["100","110","111","700","710","711" ]
    relators = {} 
    record.find_all{|f| contributors.include?(f.tag) }.each do |field|
      Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__} field = #{field.inspect}")
      if field["a"]
        contributor = clean_end_punctuation(field["a"])
        relators[contributor] = [] if relators[contributor].nil?  
        field.find_all{|sf| sf.code == 'e' }.each do |sfe|
          code = code_for_relation(clean_end_punctuation(sfe.value))  if sfe 
          relators[contributor] << code if code
        end
        field.find_all{|sf| sf.code == '4' }.each do |sf4|
          relators[contributor] << clean_end_punctuation(sf4.value) if sf4 
        end
      end
    end 
    relators
  end

  # Original comment:
  # This is a replacement method for the get_author_list method.  This new method will break authors out into primary authors, translators, editors, and compilers
  def get_all_authors(record)
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} #{__method__}")
    translator_code = "trl"; editor_code = "edt"; compiler_code = "com"
    translator_code << "translator"; editor_code << "editor"; compiler_code << "compiler"
    primary_authors = []; translators = []; editors = []; compilers = []
    corporate_authors = []; meeting_authors = []; secondary_authors = []
    primary_corporate_authors = []; secondary_corporate_authors = [];
    record.find_all{|f| f.tag === "100" }.each do |field|
      primary_authors << field["a"] if field["a"]
    end
    record.find_all{|f| f.tag === '110' || f.tag === '710'}.each do |field|
      corporate_authors << (field['a'] ? clean_end_punctuation(field['a']) : '') +
                           (field['b'] ? ' ' + field['b'] : '')
    end
    record.find_all{|f| f.tag === '110'}.each do |field|
      primary_corporate_authors << (field['a'] ? clean_end_punctuation(field['a']) : '') +
                           (field['b'] ? ' ' + field['b'] : '')
    end
    record.find_all{|f| f.tag === '710'}.each do |field|
      secondary_corporate_authors << (field['a'] ? clean_end_punctuation(field['a']) : '') +
                           (field['b'] ? ' ' + field['b'] : '')
    end
    record.find_all{|f| f.tag === '111' || f.tag === '711' }.each do |field|
      meeting_authors << (field['a'] ? field['a'] : '') +
                           (field['q'] ? ' ' + field['q'] : '')
    end
    record.find_all{|f| f.tag === "700" }.each do |field|
      if field["a"]
        relators = []
        relators << clean_end_punctuation(field["e"]) if field["e"]
        relators << clean_end_punctuation(field["4"]) if field["4"]
        if relators.include?(translator_code)
          translators << field["a"]
        elsif relators.include?(editor_code)
          editors << field["a"]
        elsif relators.include?(compiler_code)
          compilers << field["a"]
        else
          if setup_editors_flag(record) 
            editors << field["a"]
          else 
            secondary_authors << field["a"]
          end
        end
      end
    end

    primary_authors.each_with_index do |a,i|
      primary_authors[i] = a.gsub(/[\.,]$/,'')
    end
    secondary_authors.each_with_index do |a,i|
      secondary_authors[i] = a.gsub(/[\.,]$/,'')
    end
    primary_authors.uniq! 
    corporate_authors.uniq! 
    primary_corporate_authors.uniq! 
    secondary_corporate_authors.uniq! 
    translators.uniq! 
    editors.uniq! 
    compilers.uniq! 
    secondary_authors.uniq! 
    secondary_authors.delete_if { |a| primary_authors.include?(a) }
    meeting_authors.uniq! 

    ret = {:primary_authors => primary_authors, :corporate_authors => corporate_authors, :translators => translators, :editors => editors, :compilers => compilers,
    :secondary_authors => secondary_authors, :meeting_authors => meeting_authors, :primary_corporate_authors => primary_corporate_authors, :secondary_corporate_authors => secondary_corporate_authors }
    Rails.logger.debug("es287_debug **** #{__FILE__} #{__LINE__} ret = #{ret.inspect}")
    ret
  end


  def mla_citation_title(text)
    no_upcase = ["a","an","and","but","by","for","it","of","the","to","with"]
    new_text = []
    word_parts = text.split(" ")
    word_parts.each do |w|
      if !no_upcase.include? w
        new_text.push(w.capitalize)
      else
        new_text.push(w)
      end
    end
    new_text.join(" ")
  end
  
  # This will replace the mla_citation_title method with a better understanding of how MLA and Chicago citation titles are formatted.
  # This method will take in a string and capitalize all of the non-prepositions.
  def citation_title(title_text)
    prepositions = ["a","about","across","an","and","before","but","by","for","it","of","the","to","with","without"]
    new_text = []
    title_text.split(" ").each_with_index do |word,index|
      if (index == 0 and word != word.upcase) or (word.length > 1 and word != word.upcase and !prepositions.include?(word))
        # the split("-") will handle the capitalization of hyphenated words
        new_text << word.split("-").map!{|w| w.capitalize }.join("-")
      else
        new_text << word
      end
    end
    new_text.join(" ")
  end

  # I hope this can guide the interpretation of 700 when no role is encoded.
  def setup_editors_flag(record)
    title_info_field = record.find{|f| f.tag == '245'}
    edited = false
    if title_info_field
      c_title_info = title_info_field.find{|s| s.code == 'c'}
      if (c_title_info and c_title_info.value and c_title_info.value.include?("edited"))
        edited = true 
      end
    end
  edited
  end

  def setup_title_info(record)
    text = ''
    title_info_field = record.find{|f| f.tag == '245'}
    if !title_info_field.nil?
      a_title_info = title_info_field.find{|s| s.code == 'a'}
      b_title_info = title_info_field.find{|s| s.code == 'b'}
      a_title_info = clean_end_punctuation(a_title_info.value.strip) unless a_title_info.nil?
      b_title_info = clean_end_punctuation(b_title_info.value.strip) unless b_title_info.nil?
      text += a_title_info unless a_title_info.nil?
      if !a_title_info.nil? and !b_title_info.nil?
        text += ": "
      end
      text += b_title_info unless b_title_info.nil?
    end
    
    return nil if text.strip.blank?
    text.sub!(' : ' ,': ')
    clean_end_punctuation(text.strip) + "."
  end
  
  def apa_clean_end_punctuation(text)
    if [".,"].include? text[-2,2]
      return text[0,text.length-1]
    end
    text
  end  

  def clean_end_punctuation(text)
    if [".",",",":",";","/"].include? text[-1,1]
      return text[0,text.length-1]
    end
    text
  end  

  def setup_edition(record)
    edition_field = record.find{|f| f.tag == '250'}
    edition_code = edition_field.find{|s| s.code == 'a'} unless edition_field.nil?
    edition_data = edition_code.value unless edition_code.nil?
    if edition_data.nil? or edition_data == '1st ed.'
      return nil
    else
      return edition_data
    end    
  end
  

  def apa_get_author_list(record)
    author_list = []
    authors_primary = record.find{|f| f.tag == '100'}
    author_primary = authors_primary.find{|s| s.code == 'a'}.value unless authors_primary.nil? rescue ''
    author_list.push(apa_clean_end_punctuation(author_primary)) unless author_primary.nil?
    authors_secondary = record.find_all{|f| ('700') === f.tag}
    if !authors_secondary.nil?
      authors_secondary.each do |l|
        author_list.push(apa_clean_end_punctuation(l.find{|s| s.code == 'a'}.value)) unless l.find{|s| s.code == 'a'}.value.nil?
      end
    end
    author_list.uniq!
    if author_list.blank?
      authors_primary = record.find{|f| f.tag == '110'}
      author_primary = authors_primary.find{|s| s.code == 'a'}.value unless authors_primary.nil? rescue ''
      author_list.push(apa_clean_end_punctuation(author_primary)) unless author_primary.nil?
      author_list.uniq!
    end
    author_list
  end

  def get_author_list(record)
    author_list = []
    authors_primary = record.find{|f| f.tag == '100'}
    author_primary = authors_primary.find{|s| s.code == 'a'}.value unless authors_primary.nil? rescue ''
    author_list.push(clean_end_punctuation(author_primary)) unless author_primary.nil?
    authors_secondary = record.find_all{|f| ('700') === f.tag}
    if !authors_secondary.nil?
      authors_secondary.each do |l|
        author_list.push(clean_end_punctuation(l.find{|s| s.code == 'a'}.value)) unless l.find{|s| s.code == 'a'}.value.nil?
      end
    end
    
    author_list.uniq!
    author_list
  end
  
  # This is a replacement method for the get_author_list method.  This new method will break authors out into primary authors, translators, editors, and compilers
  def old_get_all_authors(record)
    translator_code = "trl"; editor_code = "edt"; compiler_code = "com"
    primary_authors = []; translators = []; editors = []; compilers = []
    record.find_all{|f| f.tag === "100" }.each do |field|
      primary_authors << field["a"] if field["a"]
    end
    record.find_all{|f| f.tag === "700" }.each do |field|
      if field["a"]
        relators = []
        relators << clean_end_punctuation(field["e"]) if field["e"]
        relators << clean_end_punctuation(field["4"]) if field["4"]
        if relators.include?(translator_code)
          translators << field["a"]
        elsif relators.include?(editor_code)
          editors << field["a"]
        elsif relators.include?(compiler_code)
          compilers << field["a"]
        else
          primary_authors << field["a"]
        end
      end
    end
    {:primary_authors => primary_authors, :translators => translators, :editors => editors, :compilers => compilers}
  end
  
  def abbreviate_name(name)
    return name unless name =~ /,/
    name_parts = name.split(", ")
    first_name_parts = name_parts.last.split(" ")
    temp_name = name_parts.first + ", " + first_name_parts.first[0,1] + "."
    first_name_parts.shift
    temp_name += " " + first_name_parts.join(" ") unless first_name_parts.empty?
    temp_name
  end

  def name_reverse(name)
    name = clean_end_punctuation(name)
    return name unless name =~ /,/
    temp_name = name.split(", ")
    return temp_name.last + " " + temp_name.first
  end 

  def relation_for_code(c)
    RELATORS.key(c) 
  end

  def code_for_relation(r)
    RELATORS[r.downcase] 
  end


RELATORS = {
"abridger" => "abr",
"actor" => "act",
"adapter" => "adp",
"addressee" => "rcp",
"analyst" => "anl",
"animator" => "anm",
"annotator" => "ann",
"appellant" => "apl",
"appellee" => "ape",
"applicant" => "app",
"architect" => "arc",
"arranger" => "arr",
"art copyist" => "acp",
"art director" => "adi",
"artist" => "art",
"artistic director" => "ard",
"assignee" => "asg",
"associated name" => "asn",
"attributed name" => "att",
"auctioneer" => "auc",
"author" => "aut",
"author in quotations or text abstracts" => "aqt",
"author of afterword, colophon, etc." => "aft",
"author of dialog" => "aud",
"author of introduction, etc." => "aui",
"autographer" => "ato",
"bibliographic antecedent" => "ant",
"binder" => "bnd",
"binding designer" => "bdd",
"blurb writer" => "blw",
"book designer" => "bkd",
"book producer" => "bkp",
"bookjacket designer" => "bjd",
"bookplate designer" => "bpd",
"bookseller" => "bsl",
"braille embosser" => "brl",
"broadcaster" => "brd",
"calligrapher" => "cll",
"cartographer" => "ctg",
"caster" => "cas",
"censor" => "cns",
"choreographer" => "chr",
"cinematographer" => "cng",
"client" => "cli",
"collection registrar" => "cor",
"collector" => "col",
"collotyper" => "clt",
"colorist" => "clr",
"commentator" => "cmm",
"commentator for written text" => "cwt",
"compiler" => "com",
"complainant" => "cpl",
"complainant-appellant" => "cpt",
"complainant-appellee" => "cpe",
"composer" => "cmp",
"compositor" => "cmt",
"conceptor" => "ccp",
"conductor" => "cnd",
"conservator" => "con",
"consultant" => "csl",
"consultant to a project" => "csp",
"contestant" => "cos",
"contestant-appellant" => "cot",
"contestant-appellee" => "coe",
"contestee" => "cts",
"contestee-appellant" => "ctt",
"contestee-appellee" => "cte",
"contractor" => "ctr",
"contributor" => "ctb",
"copyright claimant" => "cpc",
"copyright holder" => "cph",
"corrector" => "crr",
"correspondent" => "crp",
"costume designer" => "cst",
"court governed" => "cou",
"court reporter" => "crt",
"cover designer" => "cov",
"creator" => "cre",
"curator" => "cur",
"dancer" => "dnc",
"data contributor" => "dtc",
"data manager" => "dtm",
"dedicatee" => "dte",
"dedicator" => "dto",
"defendant" => "dfd",
"defendant-appellant" => "dft",
"defendant-appellee" => "dfe",
"degree granting institution" => "dgg",
"degree supervisor" => "dgs",
"delineator" => "dln",
"depicted" => "dpc",
"depositor" => "dpt",
"designer" => "dsr",
"director" => "drt",
"dissertant" => "dis",
"distribution place" => "dbp",
"distributor" => "dst",
"donor" => "dnr",
"draftsman" => "drm",
"dubious author" => "dub",
"editor" => "edt",
"editor of compilation" => "edc",
"editor of moving image work" => "edm",
"electrician" => "elg",
"electrotyper" => "elt",
"enacting jurisdiction" => "enj",
"engineer" => "eng",
"engraver" => "egr",
"etcher" => "etr",
"event place" => "evp",
"expert" => "exp",
"facsimilist" => "fac",
"field director" => "fld",
"film director" => "fmd",
"film distributor" => "fds",
"film editor" => "flm",
"film producer" => "fmp",
"filmmaker" => "fmk",
"first party" => "fpy",
"forger" => "frg",
"former owner" => "fmo",
"funder" => "fnd",
"geographic information specialist" => "gis",
"honoree" => "hnr",
"host" => "hst",
"host institution" => "his",
"illuminator" => "ilu",
"illustrator" => "ill",
"inscriber" => "ins",
"instrumentalist" => "itr",
"interviewee" => "ive",
"interviewer" => "ivr",
"inventor" => "inv",
"issuing body" => "isb",
"judge" => "jud",
"jurisdiction governed" => "jug",
"laboratory" => "lbr",
"laboratory director" => "ldr",
"landscape architect" => "lsa",
"lead" => "led",
"lender" => "len",
"libelant" => "lil",
"libelant-appellant" => "lit",
"libelant-appellee" => "lie",
"libelee" => "lel",
"libelee-appellant" => "let",
"libelee-appellee" => "lee",
"librettist" => "lbt",
"licensee" => "lse",
"licensor" => "lso",
"lighting designer" => "lgd",
"lithographer" => "ltg",
"lyricist" => "lyr",
"manufacture place" => "mfp",
"manufacturer" => "mfr",
"marbler" => "mrb",
"markup editor" => "mrk",
"medium" => "med",
"metadata contact" => "mdc",
"metal-engraver" => "mte",
"minute taker" => "mtk",
"moderator" => "mod",
"monitor" => "mon",
"music copyist" => "mcp",
"musical director" => "msd",
"musician" => "mus",
"narrator" => "nrt",
"onscreen presenter" => "osp",
"opponent" => "opn",
"organizer" => "orm",
"originator" => "org",
"other" => "oth",
"owner" => "own",
"panelist" => "pan",
"papermaker" => "ppm",
"patent applicant" => "pta",
"patent holder" => "pth",
"patron" => "pat",
"performer" => "prf",
"permitting agency" => "pma",
"photographer" => "pht",
"plaintiff" => "ptf",
"plaintiff-appellant" => "ptt",
"plaintiff-appellee" => "pte",
"platemaker" => "plt",
"praeses" => "pra",
"presenter" => "pre",
"printer" => "prt",
"printer of plates" => "pop",
"printmaker" => "prm",
"process contact" => "prc",
"producer" => "pro",
"production company" => "prn",
"production designer" => "prs",
"production manager" => "pmn",
"production personnel" => "prd",
"production place" => "prp",
"programmer" => "prg",
"project director" => "pdr",
"proofreader" => "pfr",
"provider" => "prv",
"publication place" => "pup",
"publisher" => "pbl",
"publishing director" => "pbd",
"puppeteer" => "ppt",
"radio director" => "rdd",
"radio producer" => "rpc",
"recording engineer" => "rce",
"recordist" => "rcd",
"redaktor" => "red",
"renderer" => "ren",
"reporter" => "rpt",
"repository" => "rps",
"research team head" => "rth",
"research team member" => "rtm",
"researcher" => "res",
"respondent" => "rsp",
"respondent-appellant" => "rst",
"respondent-appellee" => "rse",
"responsible party" => "rpy",
"restager" => "rsg",
"restorationist" => "rsr",
"reviewer" => "rev",
"rubricator" => "rbr",
"scenarist" => "sce",
"scientific advisor" => "sad",
"screenwriter" => "aus",
"scribe" => "scr",
"sculptor" => "scl",
"second party" => "spy",
"secretary" => "sec",
"seller" => "sll",
"set designer" => "std",
"setting" => "stg",
"signer" => "sgn",
"singer" => "sng",
"sound designer" => "sds",
"speaker" => "spk",
"sponsor" => "spn",
"stage director" => "sgd",
"stage manager" => "stm",
"standards body" => "stn",
"stereotyper" => "str",
"storyteller" => "stl",
"supporting host" => "sht",
"surveyor" => "srv",
"teacher" => "tch",
"technical director" => "tcd",
"television director" => "tld",
"television producer" => "tlp",
"thesis advisor" => "ths",
"transcriber" => "trc",
"translator" => "trl",
"type designer" => "tyd",
"typographer" => "tyg",
"university place" => "uvp",
"videographer" => "vdg",
"voice actor" => "vac",
"witness" => "wit",
"wood engraver" => "wde",
"woodcutter" => "wdc",
"writer of accompanying material" => "wam",
"writer of added commentary" => "wac",
"writer of added lyrics" => "wal",
"writer of added text" => "wat",
"writer of introduction" => "win",
"writer of preface" => "wpr",
"writer of supplementary textual content" => "wst" }

  
end
