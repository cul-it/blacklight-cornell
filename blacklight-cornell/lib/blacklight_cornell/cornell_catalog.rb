#encoding: UTF-8
module BlacklightCornell::CornellCatalog extend Blacklight::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Configurable
  #  include Blacklight::SolrHelper
  include CornellCatalogHelper
  include ActionView::Helpers::NumberHelper
  include CornellParamsHelper
  include Blacklight::SearchContext
  include Blacklight::TokenBasedUser
  include BlacklightCornell::Errors
  include BlacklightCornell::VirtualBrowse
  include BlacklightCornell::Discogs

  #  include ActsAsTinyURL
  Blacklight::Catalog::SearchHistoryWindow = 12 # how many searches to save in session history

  def set_return_path
    op = request.original_fullpath
    # if we headed for the login page, should remember PREVIOUS return to.
    if op.include?('logins') && !session[:cuwebauth_return_path].blank?
      op = session[:cuwebauth_return_path]
    end
    # Don't let the ajax urls for the virtual browse become the return path. Keep the path that's in the session.
    if (op.include?('get_next') || op.include?('get_previous')) && !session[:cuwebauth_return_path].blank?
      op = session[:cuwebauth_return_path]
    end
    op.dup.sub!('/range_limit','')

    refp = ""
    refp.sub!('/range_limit','') unless refp.nil?

    session[:cuwebauth_return_path] =
      if (params['id'].present? && params['id'].include?('|'))
        '/bookmarks'
      elsif (op.include?('/book_bags/email'))
        "/book_bags/email"
      elsif (params['id'].present? && op.include?('email'))
        "/catalog/#{params[:id]}"
      elsif (params['id'].present? && op.include?('unapi'))
        refp
      elsif (op.include?('/range_limit'))
        path = op.sub('/range_limit', '')
      else
        op
      end

    return true
  end

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    if   ENV['SAML_IDP_TARGET_URL']
      prepend_before_action :set_return_path
    end
    helper_method :search_action_url, :search_action_path, :search_facet_url, :display_helper
    before_action :search_session, :history_session
    before_action :delete_or_assign_search_session_params, :only => :index
    # before_action :add_cjk_params_logic
    after_action :set_additional_search_session_values, :only=>:index
    rescue_from Blacklight::Exceptions::RecordNotFound, :with => :record_not_found_error
    # BlacklightRangeLimit::InvalidRange is raised when an invalid date range is executed.
    rescue_from BlacklightRangeLimit::InvalidRange, :with => :range_limit_error
  end

  def search_action_path *args
    if args.first.is_a? Hash
      args.first[:only_path] = true
    end

    search_action_url(*args)
  end

  def append_facet_fields(values)
    self['facet.field'] += Array(values)
  end

  # get search results from the solr index
  def index
    begin
      # for returning to the same page on exceptions
      session[:return_to] ||= request.referer

    # check to see if the search limit has been exceeded
    session["search_limit_exceeded"] = false
    search_limit = Rails.configuration.search_limit
    page_i = params[:page].to_i
    per_page_i = params[:per_page].present? ? params[:per_page].to_i : 20
    requested_results = per_page_i * page_i
    if requested_results > search_limit
      logger.debug("******** #{__FILE__}:#{__LINE__}:#{__method__}: search limit exceeded.")
      session["search_limit_exceeded"] = true
    end
    # @bookmarks = current_or_guest_user.bookmarks
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.to_unsafe_h.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.to_unsafe_h.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )

    search_session[:per_page] = params[:per_page]

    # Check for missing or invalid pub_date_facet range values and return flash message
    if !params[:range].nil?
      notice = check_dates(params)
      if notice
        flash.now[:notice] = I18n.t("blacklight.search.errors.publication_year_range.#{notice}")
      end
    end

    # Query solr for document list
    @response = search_service.search_results(session['search_limit_exceeded'])
    
    if params.nil? || params[:f].nil?
      @filters = []
    else
      @filters = params[:f] || []
    end

    # Expand search only under certain conditions
    if expandable_search?
      query = params[:q].gsub(/&/, '%26')
      source_results = { :url => BentoSearch.get_engine(:worldcat).configuration.link + query }
      @expanded_results = { 'worldcat' => source_results }
    else
      @expanded_results = { 'worldcat' => { :url => ENV['WORLDCAT_URL'] } }
    end

    @controller = self
    if session['search_limit_exceeded']
      flash.now.alert = I18n.t('blacklight.search.search_limit_exceeded')
    end

    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json { render json: { response: { document: @response.documents } } }
    end

  rescue ArgumentError => e
    logger.error e
    flash[:notice] = e.message
    redirect_to session.delete(:return_to)
  end
  end

  # get single document from the solr index
  def show
    @document = search_service.fetch(params[:id])
    @documents = [ @document ]
    # For musical recordings, if the solr doc doesn't have a discogs id, call the Discogs module.
    # If it does have the id, save it globally and just get the image url.
    notes_check = @document["notes"].present? ? @document["notes"].join : ""
    if @document["format_main_facet"] == "Musical Recording" && @document["discogs_display"].nil? && !notes_check.include?("Cornell University") && !notes_check.include?("Ithaca")
      get_discogs_search_result(@document) unless @document['publisher_display'].present? && @document['publisher_display'][0].include?("Naxos")
    elsif @document["discogs_display"].present?
      @discogs_id = @document["discogs_display"][0]
      @discogs_image_url = get_discogs_image(@document["discogs_display"][0])
    end

    respond_to do |format|
      format.endnote_xml { render 'endnote_xml', :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.html        { @search_context = setup_next_and_previous_documents }
      format.rss         { render :layout => false }
      format.ris         { render 'ris', :layout => false }
      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
        format.send(format_name.to_sym) { render :body => @document.export_as(format_name), :layout => false }
      end
      # for the visual shelf browse
      if @document['callnumber_display'].present?
        @previous_eight = get_surrounding_docs(@document['callnumber_display'][0],"reverse",0,1)
        @next_eight = get_surrounding_docs(@document['callnumber_display'][0],"forward",0,2)
      end
    end
  end

  # Ajax endpoint for asynchronously rendering full facet value list
  # Currently only used for lc_callnum_facet
  def facet_values
    facet = blacklight_config.facet_fields[params[:id]]
    raise ActionController::RoutingError, 'Not Found' unless facet

    response = search_service.facet_field_response(facet.key)
    @display_facet = response.aggregations[facet.field]
    respond_to do |format|
      format.js { render layout: false }
    end
  end

  # method to serve up XML OpenSearch description and JSON autocomplete response
  def opensearch
    respond_to do |format|
      format.xml do
        render :layout => false
      end
      format.json do
        render :json => search_service.opensearch_response
      end
    end
  end

  # grabs a bunch of documents to export to endnote
  def endnote
    if params[:id].nil?
      bookmarks = token_or_current_or_guest_user.bookmarks
      bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }

      if bookmark_ids.size > BookBagsController::MAX_BOOKBAGS_COUNT
        bookmark_ids = bookmark_ids[0..BookBagsController::MAX_BOOKBAGS_COUNT]
      end
      # Ensure user can export all selected bookmarks and not just 1 page.
      @documents = search_service.fetch(bookmark_ids, start: 0, rows: bookmark_ids.size, per_page: bookmark_ids.size)
    else
      @documents = search_service.fetch(params[:id])
    end
    if @documents.count() < 1
      return
    end

    respond_to do |format|
      format.endnote_xml { render 'endnote_xml', layout: false }
      format.endnote     { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.ris         { render 'ris', :layout => false }
    end
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email_action documents
    mail = RecordMailer.email_record(documents, { to: params[:to], message: params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus] }, url_options, params)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  def validate_email_params
    if params[:to].blank?
      flash.now[:error] = I18n.t('blacklight.email.errors.to.blank')
    elsif !params[:to].match(Blacklight::Engine.config.blacklight.email_regexp)
      flash.now[:error] = I18n.t('blacklight.email.errors.to.invalid', to: params[:to])
    end

    flash[:error].blank?
  end

  def worldcat_number
    @id = ActionController::Base.helpers.sanitize(params[:id])

    redirect_to utf8: "✓",
      q_row: ["#{@id}", ""],
      op_row: ["AND", "AND"],
      search_field_row: ["number", "all_fields"],
      sort: "score desc, pub_date_sort desc, title_sort asc",
      search_field: "advanced",
      advanced_query: "yes",
      commit: "Search",
      controller: "catalog",
      action: "index"
  end

  def worldcat_oclc
    @id = ActionController::Base.helpers.sanitize(params[:id])

    redirect_to utf8: "✓",
      q_row: ["OCoLC #{@id}", ""],
      op_row: ["phrase", "AND"],
      search_field_row: ["number", "all_fields"],
      sort: "score desc, pub_date_sort desc, title_sort asc",
      search_field: "advanced",
      advanced_query: "yes",
      commit: "Search",
      controller: "catalog",
      action: "index"
  end

  def worldcat_isbnissn
    @id = ActionController::Base.helpers.sanitize(params[:id])

    redirect_to utf8: "✓",
      q_row: ["#{@id}", ""],
      op_row: ["AND", "AND"],
      search_field_row: ["isbnissn", "all_fields"],
      sort: "score desc, pub_date_sort desc, title_sort asc",
      search_field: "advanced",
      advanced_query: "yes",
      commit: "Search",
      controller: "catalog",
      action: "index"
    end

protected

  # sets up the session[:history] hash if it doesn't already exist.
  # assigns all Search objects (that match the searches in session[:history]) to a variable @searches.
  def history_session
    session[:history] ||= []
    @searches = searches_from_history # <- in BlacklightController
  end

  # This method copies request params to session[:search], omitting certain
  # known blacklisted params not part of search, omitting keys with blank
  # values. All keys in session[:search] are as symbols rather than strings.
  def delete_or_assign_search_session_params
    session[:search] = {}
    params.each_pair do |key, value|
      if !value.nil?
        value = value.to_unsafe_h if ['f', 'f_inclusive', 'boolean_row', 'range'].include?(key)
        session[:search][key.to_sym] = value unless ['commit', 'counter'].include?(key.to_s) ||
          value.blank?
      end
    end
  end

  # sets some additional search metadata so that the show view can display it.
  def set_additional_search_session_values
    unless @response.nil?
      search_session[:total] = @response.total
    end
  end

  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
  def record_not_found_error
    if Rails.env == 'development'
      render # will give us the stack trace
    else
      flash[:notice] = I18n.t('blacklight.search.errors.invalid_solr_id')
      params.delete(:id)
      index
      render 'index', :status => 404
    end
  end

  # When blacklight_range_limit throws an error (BlacklightRangeLimit::InvalidRange), 
  # remove the range params and redirect to a new query with an appropriate flash message
  def range_limit_error
    error = check_dates(params) || "general"
    redirect_to params.except(:range)
    flash[:notice] = I18n.t("blacklight.search.errors.publication_year_range.#{error}")
  end

  def blacklight_solr
    @solr ||=  RSolr.connect(blacklight_solr_config)
  end

  def blacklight_solr_config
    Blacklight.solr_config
  end

  def credits
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

  # Overrides from Blacklight::SearchContext to add :document_id
  def nonpersisted_search_session_params
    [:commit, :counter, :document_id, :id, :page, :per_page, :search_id, :total]
  end

private

  def cjk_mm_val
    silence_warnings { @@cjk_mm_val = '3<86%'}
  end

  # Update in blacklight_range_limit v.9 
  def check_dates(params)
    alert = nil
    pub_date_facet = params[:range][:pub_date_facet]
    unknown_pub_date_facet = params[:range]['-pub_date_facet']
    begin_year = Integer(pub_date_facet[:begin]) rescue nil
    end_year = Integer(pub_date_facet[:end]) rescue nil
    if unknown_pub_date_facet.present? || pub_date_facet[:missing].present? || (pub_date_facet[:begin].blank? && pub_date_facet[:end].blank?)
      alert
    elsif begin_year.blank?
      alert = 'begin'
    elsif end_year.blank?
      alert = 'end'
    elsif begin_year > end_year
      alert = 'order'
    end
    return alert
  end
end
