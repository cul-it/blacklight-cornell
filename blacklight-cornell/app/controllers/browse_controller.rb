# -*- encoding : utf-8 -*-
class BrowseController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightCornell::VirtualBrowse
  include BlacklightCornell::Browse

  before_action :heading
  before_action :redirect_catalog
  before_action :check_browse_and_heading_types, only: [:info]

  rescue_from RSolr::Error::Http, :with => :handle_request_error

  # Needed to prevent saving when browse field is selected with no query
  def start_new_search_session?
    false if controller_name == "browse"
  end

  def heading
   @heading='Browse'
  end

  def index
    Appsignal.increment_counter('browse_index', 1)

    if params['authq'].present? && params['authq'].is_a?(String)
      if ['Author', 'Subject', 'Author-Title', 'Call-Number'].include?(params[:browse_type])
        headingsResponseFull = browse_solr
        params[:authq].gsub!('%20', ' ')

        if params[:browse_type] == 'Call-Number'
          @headingsResponse = headingsResponseFull
          
          # TODO: Fix error when numFound < start
          # TODO: Move below to a helper method?
          if @headingsResponse['response']['numFound'] > 0 && @headingsResponse['response']['docs'][0]['classification_display'].present?
            @class_display = @headingsResponse['response']['docs'][0]['classification_display'].gsub(' > ',' <i class="fa fa-caret-right class-caret"></i> ').html_safe
          end
          @browse_locations = call_number_locations
        else
          @headingsResponse = headingsResponseFull['response']['docs']
        end
      end

      if params[:browse_type] == 'virtual'
        location = ''
        if params[:fq].present? && params[:fq].include?('location:')
          location = params[:fq]
        end
        previous_eight = get_surrounding_docs(params[:authq], 'reverse', 0, 8, location)
        next_eight = get_surrounding_docs(params[:authq], 'forward', 0, 9, location)
        if previous_eight.present? && next_eight.present?
          @headingsResponse = previous_eight.reverse() + next_eight
        end
        params[:authq].gsub!('%20', ' ')
      end

      @has_previous = check_for_previous
      @has_next = check_for_next
    end
  end

  # TODO: This is only querying the callnum index - why are we calling this for all browse_types?
  # checks to see if there are previous items to page to
  def check_for_previous
    solrResponseFull = browse_solr(order: 'reverse', rows: 0)
    solrResponseFull['response']['numFound'] > 0
  end

  # checks to see if there are more ("next") items to page to
  def check_for_next
    solrResponseFull = browse_solr(order: 'forward', rows: 0)
    solrResponseFull['response']['numFound'] > 20
  end

  def info
    Appsignal.increment_counter('browse_info', 1)

    query_params = {
      :q => "\"#{params[:authq].gsub('\\',' ')}\"",
      :wt => :ruby
    }
    query_params[:fq] = "headingTypeDesc:\"#{params[:headingtype]}\"" if params[:headingtype].present?
    solr_response = solr_for_browse(params[:browse_type]).get 'browse', :params => query_params
    solr_doc = solr_response['response']['docs'][0]
    @heading_document = solr_doc.present? ? HeadingSolrDocument.new(solr_doc) : nil

    params[:authq].gsub!('%20', ' ')

    # Get Library of Congress local name and format facet for Author and Subject heading
    if @heading_document.present?
      if params[:browse_type] == 'Author'
        loc_url = get_author_loc_url
      elsif params[:browse_type] == 'Subject'
        # Authors can also be subjects, so check. When that's the case, get the correct LOC local name.
        subject_is_author = params[:headingtype] == 'Personal Name' ? check_author_status : false
        loc_url = subject_is_author ? get_author_loc_url : get_subject_loc_url
      end

      @loc_localname = !loc_url.blank? ? loc_url.split('/').last.inspect : ''
      @formats = get_formats(params[:authq])
    else
      @formats = {}
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
    return false unless params[:authq].present?

    q = '"' + params[:authq].gsub("\\"," ").gsub('"',' ') + '"'
    results = solr_for_browse('Author').get 'browse', :params => { :q => q, :wt => :ruby }
    results['response']['numFound'] == 1
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

 def get_formats(query)
    browse_fields = @heading_document.browse_fields
    if browse_fields.empty?
      {}
    else
      query = browse_fields.map { |field| "#{field}:\"#{query}\"" }.join(' OR ')
      solr = RSolr.connect :url => ENV['SOLR_URL']
      solr_response = solr.get 'select',
        :params => {
          :q => query,
          :rows => 0,
          :mm => 1
        }

      format_facet_counts = solr_response['facet_counts']['facet_fields']['format']
      Hash[*format_facet_counts]
    end
  end

  private

  # Render error message if invalid params
  # Subject and Author browse_type require a headingtype param
  def check_browse_and_heading_types
    if params[:authq].blank? || ['Author', 'Subject', 'Author-Title'].exclude?(params[:browse_type]) ||
        (params[:headingtype].blank? && ['Author', 'Subject'].include?(params[:browse_type]))
      flash.now[:error] = 'Please enter a valid query.'
      render 'index'
    end
  end

  def browse_solr(query: nil, fq: nil, order: nil, rows: nil, start: nil, browse_type: nil)
    query = query || params[:authq].gsub('\\', ' ').gsub('"',' ')
    super(query: query,
          order: order || params[:order],
          start: start || params[:start] || 0,
          rows: rows,
          fq: fq || params[:fq],
          browse_type: browse_type || params[:browse_type])
  end
end
