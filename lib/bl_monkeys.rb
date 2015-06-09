include Blacklight::Solr::Document::MarcExport

module Blacklight::Solr::Document::MarcExport

#STANDARD_INFO =  "\n#{__FILE__} #{__LINE__} #{__method__} " 

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
        date_value = pub_date.find{|s| s.code == 'c'}.value.gsub(/[^0-9]|n\.d\./, "")[0,4] unless pub_date.find{|s| s.code == 'c'}.value.gsub(/[^0-9]|n\.d\./, "")[0,4].blank?
      end
      return nil if date_value.nil?
    end
    clean_end_punctuation(date_value) if date_value
  end


  # Main method for defining chicago style citation.  If we don't end up converting to using a citation formatting service
  # we should make this receive a semantic document and not MARC so we can use this with other formats.
  def chicago_citation(marc)
    authors = get_all_authors(marc)    
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
    citation << "#{edition} " unless edition.blank?
    citation << "#{pub_info}." unless pub_info.blank?
    citation
  end


  # Exports as an OpenURL KEV (key-encoded value) query string.
  # For use to create COinS, among other things. COinS are
  # for Zotero, among other things. TODO: This is wierd and fragile
  # code, it should use ruby OpenURL gem instead to work a lot
  # more sensibly. The "format" argument was in the old marc.marc.to_zotero
  # call, but didn't neccesarily do what it thought it did anyway. Left in
  # for now for backwards compatibilty, but should be replaced by
  # just ruby OpenURL. 
  def export_as_openurl_ctx_kev(format = 'book')  
    format = @_source["format_main_facet"]
    title = to_marc.find{|field| field.tag == '245'}
    author = to_marc.find{|field| field.tag == '100'}
    corp_author = to_marc.find{|field| field.tag == '110'}
    publisher_info = to_marc.find{|field| field.tag == '260'}
    if publisher_info.nil?  
      publisher_info = to_marc.find{|field| field.tag == '264'}
    end
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

	  

end


class String
      def is_number?
        true if Float(self) rescue false
      end
end
