# -*- encoding : utf-8 -*-
class BrowseController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightCornell::VirtualBrowse

  before_action :heading
  before_action :redirect_catalog
  before_action :check_browse_and_heading_types, only: [:info]

  @@browse_index_author = ENV['BROWSE_INDEX_AUTHOR'].nil? ? 'author' : ENV['BROWSE_INDEX_AUTHOR']
  @@browse_index_subject = ENV['BROWSE_INDEX_SUBJECT'].nil? ? 'subject' : ENV['BROWSE_INDEX_SUBJECT']
  @@browse_index_authortitle = ENV['BROWSE_INDEX_AUTHORTITLE'].nil? ? 'authortitle' : ENV['BROWSE_INDEX_AUTHORTITLE']
  @@browse_index_callnumber = ENV['BROWSE_INDEX_CALLNUMBER'].nil? ? 'callnum' : ENV['BROWSE_INDEX_CALLNUMBER']

  def heading
   @heading='Browse'
  end

  def index
      base_solr = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
      Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{base_solr}")

    Appsignal.increment_counter('browse_index', 1)
    authq = params[:authq]
    browse_type = params[:browse_type]
    if params[:start].nil?
      params[:start] = '0'
    end
    start = params[:start]
    if !authq.nil? and authq != "" and browse_type == "Author"
      dbclnt = HTTPClient.new
      p =  {"q" => '["' + authq.gsub("\\"," ").gsub('"',' ')+'" TO *]' }
      start = {"start" => start}
      if params[:order] == "reverse"
        p =  {"q" => '[* TO "' + authq.gsub("\\"," ").gsub('"',' ')+'"}' }
        # @headingsResultString = dbclnt.get_content(base_solr + "/author/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
        # @headingsResultString = @headingsResultString
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_author + "/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
        @headingsResultString = @headingsResultString
      else
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_author + "/browse?&wt=json&" + p.to_param + '&' + start.to_param )
      end
      if !@headingsResultString.nil?
         y = @headingsResultString
         @headingsResponseFull = JSON.parse(y)
         #@headingsResponseFull = eval(@headingsResultString)
      else
         @headingsResponseFull = eval("Could not find")
      end
      @headingsResponse = @headingsResponseFull['response']['docs']
      params[:authq].gsub!('%20', ' ')
    end

    if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Subject"
      dbclnt = HTTPClient.new
      p =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') + '" TO *]' }
      if params[:start].nil?
        params[:start] = '0'
      end
      start = {"start" => params[:start].gsub("\\"," ")}
      if params[:order] == "reverse"
        p =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ')+'"}' }

        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_subject + "/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
        @headingsResultString = @headingsResultString
      else
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_subject + "/browse?&wt=json&" + p.to_param + '&' + start.to_param  )
      end
      if !@headingsResultString.nil?
         y = @headingsResultString
         @headingsResponseFull = JSON.parse(y)
         #@headingsResponseFull = eval(@headingsResultString)
      else
         @headingsResponseFull = eval("Could not find")
      end
      @headingsResponse = @headingsResponseFull['response']['docs']
      params[:authq].gsub!('%20', ' ')
    end

    if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Author-Title"
      dbclnt = HTTPClient.new
      #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
      #solr = Blacklight.solr_config[:url]
      p =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') +'" TO *]' }
      start = {"start" => params[:start]}
      #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
      #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
      if params[:order] == "reverse"
        p =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ')+'"}' }
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_authortitle + "/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
        @headingsResultString = @headingsResultString
      else
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_authortitle + "/browse?wt=json&" + p.to_param + '&' + start.to_param  )
      end
      if !@headingsResultString.nil?
         y = @headingsResultString
         @headingsResponseFull = JSON.parse(y)
         #@headingsResponseFull = eval(@headingsResultString)
      else
         @headingsResponseFull = eval("Could not find")
      end
      @headingsResponse = @headingsResponseFull['response']['docs']
      params[:authq].gsub!('%20', ' ')
    end
    if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Call-Number"
      # http://da-prod-solr.library.cornell.edu/solr/callnum/browse?q=%7B!tag=mq%7D%5B%22HD8011%22%20TO%20*%5D
      call_no_solr = base_solr
      start = {"start" => params[:start]}
      dbclnt = HTTPClient.new
      if params[:order] == "reverse"
        p =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ') +'"}' }
        url = call_no_solr + "/" + @@browse_index_callnumber + "/reverse?wt=json&" + p.to_param + '&' + start.to_param
      else
        p =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') +'" TO *]' }
        url = call_no_solr + "/" + @@browse_index_callnumber + "/browse?wt=json&" + p.to_param + '&' + start.to_param
      end
      if params[:fq]
        url = url + '&fq=' + params[:fq]
      end
      @headingsResultString = dbclnt.get_content( url )
      if !@headingsResultString.nil?
        y = @headingsResultString
        @headingsResponseFull = JSON.parse(y)
      else
        @headingsResponseFull = eval("Could not find")
      end
      @headingsResponse = @headingsResponseFull
      if @headingsResponse["response"]["numFound"] > 0 && @headingsResponse["response"]["docs"][0]['classification_display'].present?
        @class_display = @headingsResponse["response"]["docs"][0]['classification_display'].gsub(' > ',' <i class="fa fa-caret-right class-caret"></i> ').html_safe
      end
      params[:authq].gsub!('%20', ' ')
    end

    @has_previous = check_for_previous if params["authq"].present?
    @has_next = check_for_next if params["authq"].present?
    if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "virtual"
      location = ""
      if params[:fq].present? && params[:fq].include?("location:")
        location = params[:fq]
      end
      previous_eight = get_surrounding_docs(params[:authq],"reverse",0,8,location)
      next_eight = get_surrounding_docs(params[:authq],"forward",0,9,location)
      if (previous_eight.present? && next_eight.present?)
        @headingsResponse = previous_eight.reverse() + next_eight
      end
      params[:authq].gsub!('%20', ' ')
    end
  end

  # checks to see if there are previous items to page to
  def check_for_previous
    base_solr_url = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
    dbclnt = HTTPClient.new
    solrResponseFull = []
    return_array = []
    q =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ') +'"]' }
    url = base_solr_url + "/" + @@browse_index_callnumber + "/reverse?wt=json&" + q.to_param + '&fl=*&start=0&rows=1'
    solrResultString = dbclnt.get_content( url )
    if !solrResultString.nil?
      y = solrResultString
      solrResponseFull = JSON.parse(y)
    else
      return false
    end
    return true if solrResponseFull['response']['numFound'] > 0
    return false if solrResponseFull['response']['numFound'] == 0
  end

  # checks to see if there are more ("next") items to page to
  def check_for_next
    base_solr_url = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
    dbclnt = HTTPClient.new
    solrResponseFull = []
    return_array = []
    q =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') +'" TO *]' }
    url = base_solr_url + "/" + @@browse_index_callnumber + "/browse?wt=json&" + q.to_param + '&fl=*&start=0&rows=1'
    solrResultString = dbclnt.get_content( url )
    if !solrResultString.nil?
      y = solrResultString
      solrResponseFull = JSON.parse(y)
    else
      return false
    end
    return true if solrResponseFull['response']['numFound'] > 20
    return false if solrResponseFull['response']['numFound'] < 21
  end

  def info
    base_solr = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
    Appsignal.increment_counter('browse_info', 1)
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{base_solr}")

    solr_collection = solr_collection(params[:browse_type])
    solr = RSolr.connect :url => "#{base_solr}/#{solr_collection}"
    query_params = {
      :q => "\"#{params[:authq].gsub('\\',' ')}\"",
      :wt => :ruby
    }
    query_params[:fq] = "headingTypeDesc:\"#{params[:headingtype]}\"" if params[:headingtype].present?
    solr_response = solr.get 'browse', :params => query_params
    @heading_document = solr_response['response']['docs'][0]

    params[:authq].gsub!('%20', ' ')

    # Get Library of Congress local name and format facet for Author and Subject heading
    if @heading_document.present? && ['Author', 'Subject'].include?(params[:browse_type])
      if params[:browse_type] == 'Author'
        loc_url = get_author_loc_url
      elsif params[:browse_type] == 'Subject'
        # Authors can also be subjects, so check. When that's the case, get the correct LOC local name.
        subject_is_author = params[:headingtype] == 'Personal Name' ? check_author_status : false
        loc_url = subject_is_author ? get_author_loc_url : get_subject_loc_url
      end

      @loc_localname = !loc_url.blank? ? loc_url.split('/').last.inspect : ''
      @formats = get_formats(params[:authq], params[:headingtype])
    else
      @formats = []
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? } #renders naked html if ajax
    end
  end

  def redirect_catalog
    if params[:browse_type]
      if params[:browse_type].include?('catalog')
        field=params[:browse_type].split(':')[1]
        redirect_to "/catalog?q=#{CGI.escape params[:authq]}&search_field=#{field}"
      end
    end
  end

 # Functions for dashboard functionality
 def check_author_status
   base_solr = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
   dbclnt = HTTPClient.new
   p =  {"q" => '"' + params[:authq].gsub("\\"," ").gsub('"',' ')+'"' }
   woof = base_solr + "/" + @@browse_index_author + "/browse?&wt=json&" + p.to_param
   resp = dbclnt.get_content(base_solr + "/" + @@browse_index_author + "/browse?&wt=json&" + p.to_param)# + '&' + start.to_param )
   results = JSON.parse(resp)
   return true if results["response"]["numFound"] == 1
   return false if results["response"]["numFound"] != 1
 end

  def get_author_loc_url
    @has_wiki_data = params[:hasWD].nil? ? false : true
    heading = @heading_document["heading"].gsub(/\.$/, '')
    path = 'https://id.loc.gov/authorities/names/suggest'
    escaped = {q: heading, rdftype: params[:headingtype].gsub(" ", ""), count: 1}.to_param
    search_url_escaped = path + '?' + escaped
    #  search_url = "https://id.loc.gov/authorities/names/suggest?q=" + heading + "&rdftype=" + params[:headingtype].gsub(" ", "") + "&count=1"
    #  url = URI.parse(URI.escape(search_url))
    url = URI.parse(search_url_escaped)
    resp = Net::HTTP.get_response(url)
    data = resp.body
    # There's no guarantee that the response will be valid JSON (handle possible error with rescue below)
    result = JSON.parse(data)
    result[3][0]
  rescue JSON::ParserError
    ''
  end

  def get_subject_loc_url
    loc_path = "subjects"
    rdf_type = "(Topic OR rdftype:ComplexSubject OR rdftype:Geographic OR rdftype:GenreForm OR rdftype:CorporateName)"
    query = params[:authq].gsub(/\s>\s/, "--")
    path = "https://id.loc.gov/authorities/" + loc_path + "/suggest"
    escaped = {q: query, rdftype: rdf_type, count: 1}.to_param
    search_url_escaped = path + '?' + escaped
    #  search_url = "https://id.loc.gov/authorities/" + loc_path + "/suggest?q=" + query + "&rdftype=" + rdf_type + "&count=1"
    #  url = URI.parse(URI.escape(search_url))
    url = URI.parse(search_url_escaped)
    resp = Net::HTTP.get_response(url)
    data = resp.body
    # There's no guarantee that the response will be valid JSON (handle possible error with rescue below)
    result = JSON.parse(data)
    return result[3][0] if query == result[1][0]
    return ""
  rescue JSON::ParserError
    ''
  end

 def get_formats(query,htype)
    qparam_hash = define_search_fields(query,htype)
    if qparam_hash.empty?
      formats = []
    else
      solr = RSolr.connect :url => ENV["SOLR_URL"]
      solr_response = solr.get 'select', :params => {
                                         :q => qparam_hash[:q],
                                         :rows => 0,
                                         :q_row => qparam_hash[:qr],
                                         :op_row => qparam_hash[:or],
                                         :search_field_row => qparam_hash[:sfr],
                                         :mm => 1
                                        }

      formats = solr_response['facet_counts']['facet_fields']['format']
    end

    # uri = "https://digital.library.cornell.edu/catalog.json?utf8=%E2%9C%93&q=#{query}&search_field=all_fields&rows=3"
    # url = Addressable::URI.parse(URI.escape(uri))
    # url.normalize
    # portal_response = JSON.load(open(url.to_s))
    # if portal_response['response']['pages']['total_count'] > 0
    #   formats << "Digital Collections"
    #   formats << portal_response['response']['pages']['total_count']
    # end
    f_count = 0
    tmp_array = []
    formats.each do |f|
      if f.class == String
        tmp_string = pluralize_format(f) + " (" + number_with_delimiter(formats[f_count + 1], :delimiter => ',').to_s + ")"
        tmp_array << tmp_string
      end
      f_count = f_count + 1
    end

    return tmp_array.sort
  end

  def pluralize_format(format)
    case format
    when "Book"
      format = "Books"
    when "Journal/Periodical"
      format = "Journals/Periodicals"
    when "Manuscript/Archive"
      format = "Manuscripts/Archives"
    when "Map"
      format = "Maps"
    when "Musical Score"
      format = "Musical Scores"
    when "Non-musical Recording"
      format = "Non-musical Recordings"
    when "Video"
      format = "Videos"
    when "Computer File"
      format = "Computer Files"
    when "Database"
      format = "Databases"
    when "Musical Recording"
      format = "Musical Recordings"
    when "Thesis"
      format = "Theses"
    when "Microform"
      format = "Microforms"
    end
    return format
  end

  def define_search_fields(query,htype)
    temp_hash = {}
    if htype == "Personal Name"
      temp_hash = {:q => '(((+author_pers_browse:"' + query + '") OR author_pers_browse:"' + query + '") OR ((+subject_pers_browse:"' + query + '") OR subject_pers_browse:"' + query + '"))',
                   :qr => [query, query],
                   :or => ["AND", "AND"],
                   :sfr => ["author_pers_browse", "subject_pers_browse"]}
    elsif htype == "Corporate Name"
      temp_hash = {:q => '(((+author_corp_browse:"' + query + '") OR author_corp_browse:"' + query + '") OR ((+subject_corp_browse:"' + query + '") OR subject_corp_browse:"' + query + '"))',
                   :qr => [query, query],
                   :or => ["AND", "AND"],
                   :sfr => ["author_corp_browse", "subject_corp_browse"]}
    elsif htype ==  "Event"
      temp_hash = {:q => '(((+author_event_browse:"' + query + '") OR author_event_browse:"' + query + '") OR ((+subject_event_browse:"' + query + '") OR subject_event_browse:"' + query + '"))',
                   :qr => [query, query],
                   :or => ["AND", "AND"],
                   :sfr => ["author_event_browse", "subject_event_browse"]}
    elsif htype ==  "Chronological Term"
      temp_hash = {:q => '((+subject_era_browse:"' + query + '") OR subject_era_browse:"' + query + '")',
                   :qr => [query, query],
                   :or => ["AND"],
                   :sfr => ["subject_era_browse"]}
    elsif htype ==  "Genre/Form Term"
      temp_hash = {:q => '((+subject_genr_browse:"' + query + '") OR subject_genr_browse:"' + query + '")',
                   :qr => [query],
                   :or => ["AND"],
                   :sfr => ["subject_genr_browse"]}
    elsif htype ==  "Geographic Name"
      temp_hash = {:q => '((+subject_geo_browse:"' + query + '") OR subject_geo_browse:"' + query + '")',
                   :qr => [query],
                   :or => ["AND"],
                   :sfr => ["subject_geo_browse"]}
    elsif htype ==  "Topical Term"
      temp_hash = {:q => '((+subject_topic_browse:"' + query + '") OR subject_topic_browse:"' + query + '")',
                   :qr => [query],
                   :or => ["AND"],
                   :sfr => ["subject_topic_browse"]}
    elsif htype ==  "Work"
      temp_hash = {:q => '((+subject_work_browse:"' + query + '") OR subject_work_browse:"' + query + '")',
                   :qr => [query],
                   :or => ["AND"],
                   :sfr => ["subject_work_browse"]}
    end
    return temp_hash
  end

  private

  def solr_collection(browseType)
    case browseType
    when 'Author'
      @@browse_index_author
    when 'Subject'
      @@browse_index_subject
    when 'Author-Title'
      @@browse_index_authortitle
    end
  end

  # Render error message if invalid params
  # Subject and Author browse_type require a headingtype param
  def check_browse_and_heading_types
    if params[:authq].blank? || ['Author', 'Subject', 'Author-Title'].exclude?(params[:browse_type]) ||
        (params[:headingtype].blank? && ['Author', 'Subject'].include?(params[:browse_type]))
      flash.now[:error] = 'Please enter a valid query.'
      render 'index'
    end
  end
end
