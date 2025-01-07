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
  include BlacklightCornell::VirtualBrowse
  include BlacklightCornell::Discogs

  #  include ActsAsTinyURL
  Blacklight::Catalog::SearchHistoryWindow = 12 # how many searches to save in session history


  def set_return_path
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
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
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  original = #{op.inspect}")
    refp = request.referer
    refp =""
    refp.sub!('/range_limit','') unless refp.nil?
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  referer path = #{refp}")

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

    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  return path = #{session[:cuwebauth_return_path]}")
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
    # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
    # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
    # which is used in the #show action here.
    # BLACKLIGHT 7 note: InvalidSolrID is no longer included as a Blacklight Excreption
    # and raises an unititialized constant error. A RecordNotFound error is now raised.
    # rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error
    rescue_from Blacklight::Exceptions::RecordNotFound, :with => :record_not_found_error
    # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
    # The index action will more than likely throw this one.
    # Example, when the standard query parser is used, and a user submits a "bad" query.
    rescue_from RSolr::Error::Http, :with => :rsolr_request_error
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
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{params.inspect}"
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.to_unsafe_h.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.to_unsafe_h.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )

    search_session[:per_page] = params[:per_page]

    # Check for missing pub_date_facet range values
    if (!params[:range].nil?)
      check_dates(params)
    end

    # Sanitize query for constraints display
    if  !params[:q].blank? && !params[:search_field].blank?
      if params[:q].include?('%2520')
        params[:q].gsub!('%2520',' ')
      end
      if params[:q].include?('%2F') or params[:q].include?('/')
        params[:q].gsub!('%2F','')
        params[:q].gsub!('/','')
      end
      params[:q] = sanitize(params)
    end

    # Query solr for document list
    (@response, deprecated_document_list) = search_service.search_results(session['search_limit_exceeded'])
    @document_list = deprecated_document_list

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
      format.json { render json: { response: { document: deprecated_document_list } } }
    end

    # Format query for constraints display
    if params[:q_row].present? && params[:q_row] != ['', '']
      params[:show_query] = make_show_query(params)
      search_session[:q] = params[:show_query]
    end

  rescue ArgumentError => e
    logger.error e
    flash[:notice] = e.message
    redirect_to session.delete(:return_to)
  end
  end

  # get single document from the solr index
  def show
    @response, @document = search_service.fetch params[:id]
    @documents = [ @document ]
    # set_bag_name
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{params.inspect}"

    # For musical recordings, if the solr doc doesn't have a discogs id, call the Discogs module.
    # If it does have the id, save it globally and just get the image url.
    notes_check = @document["notes"].present? ? @document["notes"].join : ""
    if @document["format_main_facet"] == "Musical Recording" && @document["discogs_display"].nil? && !notes_check.include?("Cornell University") && !notes_check.include?("Ithaca")
      process_discogs(@document) unless @document['publisher_display'].present? && @document['publisher_display'][0].include?("Naxos")
    elsif @document["discogs_display"].present?
      @discogs_id = @document["discogs_display"][0]
      @discogs_image_url = get_discogs_image(@document["discogs_display"][0])
    end

    respond_to do |format|
      format.endnote_xml { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.html        {setup_next_and_previous_documents}
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
        @previous_eight = get_surrounding_docs(@document['callnumber_display'][0].gsub("\\"," ").gsub('"',' '),"reverse",0,1)
        @next_eight = get_surrounding_docs(@document['callnumber_display'][0].gsub("\\"," ").gsub('"',' '),"forward",0,2)
      end
    end
  end

  def setup_next_and_previous_documents
    query_params = session[:search] ? session[:search].dup : {}
    # if  !query_params[:q].blank? and !query_params[:search_field].blank? # and !params[:search_field].include? '_cts'
    #   check_params(query_params)
    # else
    #   if query_params[:q].blank?
    #     temp_search_field = query_params[:search_field]
    #     query_params[:search_field] = 'all_fields'
    #   end
    # end

    if search_session['counter']
      index = search_session['counter'].to_i - 1
      logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{query_params.inspect}"
      response, documents = search_service.previous_and_next_documents_for_search index, ActiveSupport::HashWithIndifferentAccess.new(query_params)
      search_session['total'] = response.total
      if query_params[:per_page].nil?
        query_params[:per_page] = '20'
      end
      search_session['per_page'] = query_params[:per_page]
      @search_context_response = response
      @previous_document = documents.first
      @next_document = documents.last
    end
  rescue Blacklight::Exceptions::InvalidRequest => e
    logger.warn "Unable to setup next and previous documents: #{e}"
  end

  def track
    search_session[:counter] = params[:counter]
    search_session['counter'] = params[:counter]
    #search_session[:per_page] = params[:per_page]

    path =
      if params[:redirect] and (params[:redirect].start_with?('/') or params[:redirect] =~ URI::regexp)
        URI.parse(params[:redirect]).path
      else
        { action: 'show' }
      end
    redirect_to path, :status => 303
  end

  # updates the search counter (allows the show view to paginate)
  def update
    adjust_for_results_view
    session[:search][:counter] = params[:counter]
    redirect_to :action => 'show'
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
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    if params[:id].nil?
      bookmarks = token_or_current_or_guest_user.bookmarks
      bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }
      Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  bookmark_ids = #{bookmark_ids.inspect}")
      Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  bookmark_ids size  = #{bookmark_ids.size.inspect}")
      if bookmark_ids.size > BookBagsController::MAX_BOOKBAGS_COUNT
        bookmark_ids = bookmark_ids[0..BookBagsController::MAX_BOOKBAGS_COUNT]
      end
      @response, @documents = search_service.fetch(bookmark_ids, :per_page => 1000,:rows => 1000)
      Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  @documents = #{@documents.size.inspect}")
    else
      @response, @documents = search_service.fetch(params[:id])
    end
    if @documents.count() < 1
      return
    end
    fmt = params[:format]
    Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  #{__method__} = #{fmt}")
    respond_to do |format|
      format.endnote_xml { render "show.endnote_xml" ,layout: false }
      format.endnote     { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.ris         { render 'ris', :layout => false }
    end
  end

  def sms_action documents
    to = "#{params[:to].gsub(/[^\d]/, '')}@#{params[:carrier]}"
    tinyPass = request.protocol + request.host_with_port + solr_document_path(params['id'])
    tiny = tiny_url(tinyPass)
    mail = RecordMailer.sms_record(documents, { :to => to, :callnumber => params[:callnumber], :location => params[:location], :tiny => tiny},  url_options)
    print mail.pretty_inspect
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  def validate_sms_params
    if params[:to].blank?
      flash.now[:error] = I18n.t('blacklight.sms.errors.to.blank')
    elsif params[:carrier].blank?
      flash.now[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
    elsif params[:to].gsub(/[^\d]/, '').length != 10
      flash.now[:error] = I18n.t('blacklight.sms.errors.to.invalid', to: params[:to])
    elsif !sms_mappings.value?(params[:carrier])
      flash.now[:error] = I18n.t('blacklight.sms.errors.carrier.invalid')
    end

    flash[:error].blank?
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
    elsif !params[:to].match(Blacklight::Engine.config.email_regexp)
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
        value = value.to_unsafe_h if key == "f"
        session[:search][key.to_sym] = value unless ['commit', 'counter'].include?(key.to_s) ||
          value.blank?
      end
    end
    session[:gearch] = {}
    params.each_pair do |key, value|
      session[:gearch][key.to_sym] = value unless ['commit', 'counter'].include?(key.to_s) ||
        value.blank?
    end
  end

  # sets some additional search metadata so that the show view can display it.
  def set_additional_search_session_values
    unless @response.nil?
      search_session[:total] = @response.total
    end
  end

  # we need to know if we are viewing the item as part of search results so we know whether to
  # include certain partials or not
  def adjust_for_results_view
    if params[:results_view] == 'false'
      session[:search][:results_view] = false
    else
      session[:search][:results_view] = true
    end
  end

  # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
  def rsolr_request_error(exception)
    if Rails.env.development?
      raise exception # Rails own code will catch and give usual Rails error page with stack trace
    else
      flash_notice = I18n.t('blacklight.search.errors.request_error')

      # If there are errors coming from the index page, we want to trap those sensibly
      if flash[:notice] == flash_notice
        logger.error 'Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception'
        raise exception
      end

      logger.error exception
      flash[:notice] = flash_notice
      redirect_to root_path
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

  def blacklight_solr
    @solr ||=  RSolr.connect(blacklight_solr_config)
  end

  def blacklight_solr_config
    Blacklight.solr_config
  end

  # This is a weird function -- it has two different return types, depending on an option that is apparently
  # never used! Commenting this version out and redefining generate_uri below....
  # def tiny_url(uri, options = {})
  #   defaults = { :validate_uri => false }
  #   options = defaults.merge options
  #   return validate_uri(uri) if options[:validate_uri]
  #   return generate_uri(uri)
  # end

  def credits
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

private

  def uri_valid?(uri)
    !!(uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix] ||
    uri[/^(http|https):\/\/localhost(:[0-9]{1,5})?(\/.*)?$/ix])
  end

  # def validate_uri(uri)
  #   confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix] ||
  #                   uri[/^(http|https):\/\/localhost(:[0-9]{1,5})?(\/.*)?$/ix]
  #   if confirmed_uri.blank?
  #     return false
  #   else
  #     return true
  #   end
  # end

 # def generate_uri(uri)
  def tiny_url(uri)
    Appsignal.increment_counter('item_sms', 1)
    if uri_valid?(uri)
      shorten = Rails.application.config.url_shorten
      logger.info "URL shortener:  #{__FILE__}:#{__LINE__}:#{__method__} #{shorten.pretty_inspect}"
      if shorten.present?
        escaped_uri = CGI::escape(uri)
        url = "#{shorten}#{escaped_uri}"
        begin
          uri_parsed = Net::HTTP.get_response(URI.parse(url)).body
          #uri_parsed = Net::HTTP.get_response(URI.parse(escaped_uri),{:read_timeout => 10}).body
        rescue StandardError  => e
          logger.error "URL shortener error:  #{__FILE__}:#{__LINE__}:#{__method__} #{e} #{shorten}"
          Appsignal.send_error(e)
          uri_parsed = uri
         end
      end
      return uri_parsed
    else
     # needs error checking.
     # raise ActsAsTinyURLError.new("Provided URL is incorrectly formatted.")
    end
  end

  def cjk_mm_val
    silence_warnings { @@cjk_mm_val = '3<86%'}
  end

  def check_dates(params)
    # check for Publication Year 'Unknown' - handled ok
    if params[:range][:pub_date_facet][:missing].present?
      return
    end
    # crashes later on if begin > end so raise exception here
    begin_test = Integer(params[:range][:pub_date_facet][:begin]) rescue nil
    end_test = Integer(params[:range][:pub_date_facet][:end]) rescue nil
    min_year = 0
    unless begin_test.present? && begin_test >= min_year
      raise ArgumentError.new(I18n.t('blacklight.search.errors.publication_year_range.begin'))
    end
    unless end_test.present? && end_test >= min_year
      raise ArgumentError.new(I18n.t('blacklight.search.errors.publication_year_range.end'))
    end
    unless begin_test <= end_test
      raise ArgumentError.new(I18n.t('blacklight.search.errors.publication_year_range.order'))
    end
  end

  def sanitize(q)
    if q[:q].include?('<img')
      Rails.logger.error("Sanitize error:  #{__FILE__}:#{__LINE__}  q = #{q[:q].inspect}")
      redirect_to root_path
    else
      q = params[:q].rstrip
      while (q[-1] == "/" or q[-1] == "\\") do
        if q[-1] == "/" or q[-1] == "\\"
          q[-1] = ""
          q = q.rstrip
        end
      end
      return q
    end
  end
end
