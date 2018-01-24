#include Blacklight::Solr::Document::MarcExport

if false

module Blacklight::Solr #::Document::MarcExport

#STANDARD_INFO =  "\n#{__FILE__} #{__LINE__} #{__method__} "

# NOTE: all of the functions below are copied and modified from the
# blacklight-marc gem.


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
    date_value = ''
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

  # Original comment:
  # This is a replacement method for the get_author_list method.  This new method will break authors out into primary authors, translators, editors, and compilers
  def get_all_authors(record)
    translator_code = "trl"; editor_code = "edt"; compiler_code = "com"
    primary_authors = []; translators = []; editors = []; compilers = []
    corporate_authors = []; meeting_authors = []; secondary_authors = []
    record.find_all{|f| f.tag === "100" }.each do |field|
      primary_authors << field["a"] if field["a"]
    end
    record.find_all{|f| f.tag === '110' || f.tag === '710'}.each do |field|
      corporate_authors << (field['a'] ? field['a'] : '') +
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
          secondary_authors << field["a"]
        end
      end
    end

    primary_authors.each_with_index do |a,i|
      primary_authors[i] = a.gsub(/[\.,]$/,'')
    end
    secondary_authors.each_with_index do |a,i|
      secondary_authors[i] = a.gsub(/[\.,]$/,'')
    end

    {:primary_authors => primary_authors, :corporate_authors => corporate_authors, :translators => translators, :editors => editors, :compilers => compilers,
    :secondary_authors => secondary_authors, :meeting_authors => meeting_authors }
  end

  # Original comment:
  # Main method for defining chicago style citation.  If we don't end up converting to using a citation formatting service
  # we should make this receive a semantic document and not MARC so we can use this with other formats.
  def chicago_citation(marc)
    authors = get_all_authors(marc)
    author_text = ""

    # If there are secondary (i.e. from 700 fields) authors, add them to
    # primary authors only if there are no corporate, meeting, primary authors
    if !authors[:primary_authors].blank?
      authors[:primary_authors] += authors[:secondary_authors] unless authors[:secondary_authors].blank?
    elsif !authors[:secondary_authors].blank?
      authors[:primary_authors] = authors[:secondary_authors] if (authors[:corporate_authors].blank? and authors[:meeting_authors].blank?)
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
        author_text << authors[:primary_authors].first
      end
    elsif !authors[:corporate_authors].blank?
      # This is a simplistic assumption that the first corp author entry
      # is the only one of interest (and it's not too long)
      author_text << authors[:corporate_authors].first + '.'
    elsif !authors[:meeting_authors].blank?
      # This is a simplistic assumption that the first corp author entry
      # is the only one of interest (and it's not too long)
      author_text << authors[:meeting_authors].first + '.'
    else
      # Secondary authors: translators, editors, compilers
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

  def apa_citation(record)
    text = ''
    authors_list = []
    authors_list_final = []

    #setup formatted author list
    authors = get_all_authors(record)

    # If there are secondary (i.e. from 700 fields) authors, add them to
    # primary authors only if there are no corporate, meeting, or primary authors
    if !authors[:primary_authors].empty?
      authors[:primary_authors] += authors[:secondary_authors] unless authors[:secondary_authors].blank?
    elsif !authors[:secondary_authors].blank?
      authors[:primary_authors] = authors[:secondary_authors] if (authors[:corporate_authors].blank? and authors[:meeting_authors].blank?)
    end

    if !authors[:primary_authors].blank?
      authors[:primary_authors].each do |l|
        authors_list.push(abbreviate_name(l)) unless l.blank?
      end
      authors_list.each do |l|
        if l == authors_list.first #first
          authors_list_final.push(l.strip)
        elsif l == authors_list.last #last
          authors_list_final.push(", &amp; " + l.strip)
        else #all others
          authors_list_final.push(", " + l.strip)
        end
      end
    # Handling of corporate and meeting authors here is a bit naive —
    # assuming that only the first array item is important and ends with
    # an unwanted period
    elsif !authors[:corporate_authors].blank?
      authors_list_final.push authors[:corporate_authors][0].gsub(/\.$/,'')
    elsif !authors[:meeting_authors].blank?
      authors_list_final.push authors[:meeting_authors][0].gsub(/\.$/,'')
    end

    text += authors_list_final.join
    unless text.blank?
      if text[-1,1] == '.'
        text += ' '
      elsif text[-2,2] != '. '
        text += '. '
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

  def mla_citation(record)
   text = ''
   authors_final = []

   #setup formatted author list
   authors = get_all_authors(record)

   # If there are secondary (i.e. from 700 fields) authors, add them to
   # primary authors only if there are no corporate, meeting, or primary authors
   if !authors[:primary_authors].empty?
     authors[:primary_authors] += authors[:secondary_authors] unless authors[:secondary_authors].blank?
   elsif !authors[:secondary_authors].blank?
     authors[:primary_authors] = authors[:secondary_authors] if (authors[:corporate_authors].blank? and authors[:meeting_authors].blank?)
   end

   if !authors[:primary_authors].blank?
     Rails.logger.warn "mjc12test: auth: #{authors[:primary_authors]}"
     if authors[:primary_authors].length < 4
       authors[:primary_authors].each do |l|
         l.gsub(/[\.,]$/,'')
         if l == authors[:primary_authors].first #first
           authors_final.push(l)
         elsif l == authors[:primary_authors].last #last
           authors_final.push(", and " + name_reverse(l) + ".")
         else #all others
           authors_final.push(", " + name_reverse(l) + '.')
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
       text += authors[:primary_authors].first.gsub(/\.$/,'') + ", et al. "
     end
   # Handling of corporate and meeting authors here is a bit naive —
   # assuming that only the first array item is important and ends with
   # a period
   elsif !authors[:corporate_authors].blank?
     text += authors[:corporate_authors][0] + '. '
   elsif !authors[:meeting_authors].blank?
     text += authors[:meeting_authors][0] + '. '
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

  # Original comment:
  # Exports as an OpenURL KEV (key-encoded value) query string.
  # For use to create COinS, among other things. COinS are
  # for Zotero, among other things. TODO: This is wierd and fragile
  # code, it should use ruby OpenURL gem instead to work a lot
  # more sensibly. The "format" argument was in the old marc.marc.to_zotero
  # call, but didn't neccesarily do what it thought it did anyway. Left in
  # for now for backwards compatibilty, but should be replaced by
  # just ruby OpenURL.
  def export_as_openurl_ctx_kev(format = 'book')
    Rails.logger.debug "*********es287_dev:#{__FILE__} #{__LINE__} #{__method__} "
    format = @_source["format_main_facet"]
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__} format = #{format}"
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
  def setup_format
    format
  end


end

end # of if false.

module BlacklightMarcHelper

  def render_endnote_xml_texts(documents)
    val = ''
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__}"
    documents.each do |doc|
      tmp = ''
      if doc.exports_as? :endnote_xml
        tmp = doc.export_as(:endnote_xml) + "\n"
        tmp.sub!('<xml>','')
        tmp.sub!('</xml>','')
        tmp.sub!('<records>','')
        tmp.sub!('</records>','')
        val += tmp
      end
    end
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__} val = #{val}"
   "<xml><records> #{val} </records></xml>"
  end

  # puts together a collection of documents into one ris export string
  def render_ris_texts(documents)
    val = ''
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__}"
    documents.each do |doc|
      if doc.exports_as? :ris
        val += doc.export_as(:ris) + "\n"
      end
    end
    val
  end
end

# need not to fail when uri contains | 
# This overrides the DEFAULT_PARSER with the UNRESERVED key, including '|'
# # DEFAULT_PARSER is used everywhere, so its better to override it once
 module URI
   remove_const :DEFAULT_PARSER
   unreserved = REGEXP::PATTERN::UNRESERVED
   DEFAULT_PARSER = Parser.new(:UNRESERVED => unreserved + "|")
 end




############ need different options on piwik.
#
module PiwikAnalytics
  module Helpers
    def piwik_tracking_tag_bl
      config = PiwikAnalytics.configuration
      return if config.disabled?
      piw_site = config.id_site
      if ((!config.site2_path.nil?) && (request.path == config.site2_path) ) 
        piw_site = config.id_site2
      end
      if config.use_async?
        tag = <<-CODE
        <!-- Piwik -->
        <script type="text/javascript">
        var _paq = _paq || [];
        (function(){
            var u=(("https:" == document.location.protocol) ? "https://#{config.url}/" : "http://#{config.url}/");
            _paq.push(["setDocumentTitle", document.domain + "/" + document.title]); 
            _paq.push(["setCookieDomain", "*.library.cornell.edu"]); 
             _paq.push(["setDomains", ["*.library.cornell.edu","*.newcatalog.library.cornell.edu","*.search.library.cornell.edu"]]);
            _paq.push(['setSiteId', #{piw_site}]);
            _paq.push(['setTrackerUrl', u+'piwik.php']);
            _paq.push(['trackPageView']);
            var d=document,
                g=d.createElement('script'),
                s=d.getElementsByTagName('script')[0];
                g.type='text/javascript';
                g.defer=true;
                g.async=true;
                g.src=u+'piwik.js';
                s.parentNode.insertBefore(g,s);
        })();
        </script>
        <!-- End Piwik Tag -->
        CODE
        tag.html_safe
      else
        tag = <<-CODE
        <!-- Piwik -->
        <script type="text/javascript">
        var pkBaseURL = (("https:" == document.location.protocol) ? "https://#{config.url}/" : "http://#{config.url}/");
        document.write(unescape("%3Cscript src='" + pkBaseURL + "piwik.js' type='text/javascript'%3E%3C/script%3E"));
        </script><script type="text/javascript">
        try {
                var piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", #{piw_site});
                piwikTracker.trackPageView();
                piwikTracker.enableLinkTracking();
        } catch( err ) {}
        </script>
        <!-- End Piwik Tag -->
        CODE
        tag.html_safe
      end
    end
  end
end


module PiwikAnalytics
  class  Configuration
  # The ID of the second website
    def id_site2
      @id_site2 ||= (user_configuration_from_key('id_site2') || 2)
    end

    def site2_path
      @site2_path ||= (user_configuration_from_key('site2_path') || "site2 missing")
    end

  end
end


