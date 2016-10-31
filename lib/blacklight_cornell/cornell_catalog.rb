#encoding: UTF-8
module BlacklightCornell::CornellCatalog extend Blacklight::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Configurable
#  include Blacklight::SolrHelper
  include CornellCatalogHelper
  include Blacklight::SearchHelper
  include ActionView::Helpers::NumberHelper
  include CornellParamsHelper
  include Blacklight::SearchContext
#  include ActsAsTinyURL
Blacklight::Catalog::SearchHistoryWindow = 12 # how many searches to save in session history


  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :search_action_url, :search_action_path, :search_facet_url
    before_filter :search_session, :history_session
    before_filter :delete_or_assign_search_session_params, :only => :index
#    before_filter :add_cjk_params_logic
    after_filter :set_additional_search_session_values, :only=>:index
    # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
    # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
    # which is used in the #show action here.
    rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error
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
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )

    # @bookmarks = current_or_guest_user.bookmarks
    if (!params[:range].nil?)
      check_dates(params)
    end
    # params.delete("q_row")
    qparam_display = ''
    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
 #   if params[:q_row].present?
 #     query_string = set_advanced_search_params(params)
 #   else
 #      if !params[:q].nil? and !params[:q].blank?
 #        query_string = parse_stem(params[:q])
 #        if params[:q_row].present?
 #        query_string = set_advanced_search_params(params)
 #        end
 #       end
 #     end
      # End of secondary parsing
       
#       params["spellcheck.maxResultsForSuggest"] = 1      
#     params["spellcheck.q"]= "subject=bauhaus"  
      #end of secondary parsing

    # Journal title search hack.
    if (params[:search_field].present? and params[:search_field] == 'journal title') or (params[:search_field_row].present? and params[:search_field_row].index('journal title'))
      if params[:f].nil?
        params[:f] = {'format' => ['Journal/Periodical']}
      end
        params[:f].merge('format' => ['Journal/Periodical'])
        # unless(!params[:q])
#        params[:q] = params[:q]
        if (params[:search_field_row].present? and params[:search_field_row].index('journal title'))
          params[:search_field] = 'advanced'
        else
          params[:search_field] = 'journal title'
        end
        search_session[:f] = params[:f]
    end

    #quote the call number
    if params[:search_field] == 'call number'
      if !params[:q].nil? and !params[:q].include?('"')
        params[:q] = '"' << params[:q] << '"'
        search_session[:q] = params[:q]
      end
    end
    if params[:search_field] != 'journal title ' and params[:search_field] != 'call number'
     if !params[:q].nil? and (params[:q].include?('OR') or params[:q].include?('AND') or params[:q].include?('NOT'))
       params[:q] = params[:q]
     else
      if !params[:q].nil? and !params[:q].include?('"') and !params[:q].blank?
          qparam_display = params[:q]
          params[:qdisplay] = params[:q]
          qarray = params[:q].split
          params[:q] = '('
          if qarray.size == 1
            params[:q] << '+' << qarray[0] << ') OR "' << qarray[0] << '"'
          else
            qarray.each do |bits|
              params[:q] << '+' << bits << ' '
            end
            params[:q] << ') OR "' << qparam_display << '"'
          end#encoding: UTF-8
      else
        if params[:q].nil? or params[:q].blank?
          params[:q] = qparam_display
        end
      end
     end
    
    end
    # end of Journal title search hack

#    if params[:search_field] = "call number"
#      params[:q] = "\"" << params[:q] << "\""
#    end
#    params[:q] = ' _query_:"{!edismax qf=$subject_qf pf=$subject_pf}bauhaus"  AND  _query_:"{!edismax qf=$title_qf pf=$title_pf}history"  OR  _query_:"{!edismax qf=$all_fields_qf pf=$all_fields_pf}design"'

    Rails.logger.info("BRUDDER = #{params}")

    (@response, @document_list) = search_results(params)
    #logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} response = #{@response.inspect}"
    #logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} document_list = #{@document_list.inspect}"

    if params.nil? || params[:f].nil?
      @filters = []
    else
      @filters = params[:f] || []
    end

    # clean up search_field and q params.  May be able to remove this
    if params[:search_field] == 'journal title'
       if params[:q].nil?
         params[:search_field] = ''
       end
    end

#    if params[:q_row].present?
#       if params[:q].nil?
#        params[:q] = query_string
#       end
#    else
        if params[:q].nil?
          if !params[:search_field].nil?
             params.delete(:search_field)
         end
        end

    if params[:search_field] == 'call number'
      if !params[:q].nil? and params[:q].include?('"')
        params[:q] = params[:q].gsub!('"','')
      end
    end
    # end of cleanup of search_field and q params

    @expanded_results = {}
    ['worldcat', 'summon'].each do |key|
      @expanded_results [key] =  { :count => 0 , :url => '' }
    end
    # Expand search only under certain conditions
    tmp = BentoSearch::Results.new
    if !(params[:search_field] == 'call number')
    if expandable_search?
      searcher = BentoSearch::MultiSearcher.new(:summon, :worldcat)
      logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{params.inspect}"
      logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params[:q] = #{params[:q].inspect}"
      query = ( params[:qdisplay]?params[:qdisplay] : params[:q]).gsub(/&/, '%26')
      logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} query = #{query.inspect}"
      searcher.search(query, :per_page => 1)

      @expanded_results = {}


      searcher.results.each_pair do |key, result|
        source_results = {
          :count => number_with_delimiter(result.total_items),
          :url => BentoSearch.get_engine(key).configuration.link + query,
        }
        @expanded_results[key] = source_results
      end
    end
    end

    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
    
     if !params[:q_row].nil?       
       params[:show_query] = make_show_query(params)
       search_session[:q] = params[:show_query]
     end
    if !qparam_display.blank?
#      params[:q] = qparam_display
#      search_session[:q] = params[:show_query]
      params[:q] = qparam_display
      search_session[:q] = params[:q] 
      params[:sort] = "score desc, pub_date_sort desc, title_sort asc"
    end

  end


  # get single document from the solr index
  def show
    @response, @document = fetch params[:id]
    @documents = [ @document ]
    respond_to do |format|
      format.endnote  { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.html {setup_next_and_previous_documents}
      format.rss  { render :layout => false }
      format.ris      { render 'ris', :layout => false }
      #format.ris      { render "ris", :layout => false }
      # Add all dynamically added (such as by document extensions)
      # export formats.
#        @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
#          format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
#        end

    end
  end

  def setup_next_and_previous_documents
    query_params = session[:search] ? session[:search].dup : {}
    Rails.logger.info("SQUIRTLE = #{query_params[:qdisplay]}")
    if search_session['counter'] 
      index = search_session['counter'].to_i - 1
      response, documents = get_previous_and_next_documents_for_search index, ActiveSupport::HashWithIndifferentAccess.new(query_params)
      search_session['total'] = response.total
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
      search_session['per_page'] = params[:per_page]

      path = 
        if params[:redirect] and (params[:redirect].starts_with?('/') or params[:redirect] =~ URI::regexp)
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

    # displays values and pagination links for a single facet field


    # method to serve up XML OpenSearch description and JSON autocomplete response
    def opensearch
      respond_to do |format|
        format.xml do
          render :layout => false
        end
        format.json do
          render :json => get_opensearch_response
        end
      end
    end

    # citation action
    def citation
      @response, @documents = fetch(params[:id])
    end
    # grabs a bunch of documents to export to endnote
    def endnote
      @response, @documents = fetch(params[:id])
      respond_to do |format|
        format.endnote  { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
        format.ris      { render 'ris', :layout => false }
      end
    end

    # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    # Added callnumber and location parameters to RecordMailer.email_record() call   jac244
##    def email
##      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])

##      if request.post?
##        if params[:to]
##          url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}

##          if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
##            email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :location=> params[:location] }, url_gen_params)
##          else
##            flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
##          end
##        else
##          flash[:error] = I18n.t('blacklight.email.errors.to.blank')
##        end

##        unless flash[:error]
##          email.deliver
##          flash[:success] = "Email sent"
##          redirect_to facet_catalog_path(params['id']) unless request.xhr?
##        end
##      end

##      unless !request.xhr? && flash[:success]
##        respond_to do |format|
##          format.js { render :layout => false }
##          format.html
##        end
##      end
##    end
     def sms_action documents
       to = "#{params[:to].gsub(/[^\d]/, '')}@#{params[:carrier]}"
       tinyPass = request.protocol + request.host_with_port + facet_catalog_path(params['id'])
       tiny = tiny_url(tinyPass)
       mail = RecordMailer.sms_record(documents, { :to => to, :callnumber => params[:callnumber], :location => params[:location], :tiny => tiny},  url_options)
       print mail.pretty_inspect
       if mail.respond_to? :deliver_now
         mail.deliver_now
       else
         mail.deliver
       end
     end
    # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def sms
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      if request.post?
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}
        tinyPass = request.protocol + request.host_with_port + facet_catalog_path(params['id'])
        tiny = tiny_url(tinyPass)
        if params[:to]
          phone_num = params[:to].gsub(/[^\d]/, '')
          unless params[:carrier].blank?
            if phone_num.length != 10
              flash[:error] = I18n.t('blacklight.sms.errors.to.invalid', :to => params[:to])
            else
              email = RecordMailer.sms_record(@documents, {:to => phone_num, :carrier => params[:carrier], :callnumber => params[:callnumber], :location => params[:location], :tiny => tiny}, url_gen_params)
            end

          else
            flash[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
          end
        else
          flash[:error] = I18n.t('blacklight.sms.errors.to.blank')
        end

        unless flash[:error]
          email.deliver
          flash[:success] = 'Text sent'
          redirect_to facet_catalog_path(params['id']) unless request.xhr?
        end
      end
      unless !request.xhr? && flash[:success]
        respond_to do |format|
          format.js { render :layout => false }
          format.html
        end
      end
    end


    def librarian_view
      @response, @document = fetch params[:id]

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end

    protected
    #
    # non-routable methods ->
    #

    # calls setup_previous_document then setup_next_document.
    # used in the show action for single view pagination.

    #These don't work any more
  #  def setup_next_and_previous_documents
  #    setup_previous_document
  #    setup_next_document
  #  end

    # gets a document based on its position within a resultset


  #  def setup_previous_document
  #    @previous_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i - 1) : nil
#    end

  #  def setup_next_document
  #    @next_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i + 1) : nil
  #  end

    # sets up the session[:search] hash if it doesn't already exist
    #def search_session
    #  session[:search] ||= {}
      #if session[:search].nil?
      #  session.assign_attributes({:search => {} }, :without_protection => true)
      #  session.save
      #end
    #end

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
        session[:search][key.to_sym] = value unless ['commit', 'counter'].include?(key.to_s) ||
          value.blank?
      end
      session[:gearch] = {}
      params.each_pair do |key, value|
        session[:gearch][key.to_sym] = value unless ['commit', 'counter'].include?(key.to_s) ||
          value.blank?
      end
    end

    # Saves the current search (if it does not already exist) as a models/search object
    # then adds the id of the search object to session[:history]
    
    #jac244 Commented out code because it was creating 2 entries in search history 9/27/2016
    def save_current_search_params
      # If it's got anything other than controller, action, total, we
      # consider it an actual search to be saved. Can't predict exactly
      # what the keys for a search will be, due to possible extra plugins.
#      return if (search_session.keys - [:controller, :action, :total, :counter, :commit ]) == []
#      params_copy_h = search_session.clone # don't think we need a deep copy for this
#      params_copy_h.delete(:page)
#      params_copy =  ActiveSupport::HashWithIndifferentAccess.new(params_copy_h)

#      unless @searches.collect { |search| search.query_params }.include?(params_copy)

       #new_search = Search.create(:query_params => params_copy)

#       new_search = Search.new
#       new_search.assign_attributes({:query_params => params_copy}, :without_protection => true)
#       new_search.save

#        session[:history].unshift(new_search.id)
        # Only keep most recent X searches in history, for performance.
        # both database (fetching em all), and cookies (session is in cookie)
#        session[:history] = session[:history].slice(0, Blacklight::Catalog::SearchHistoryWindow )
#      end
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
    def invalid_solr_id_error
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

  # solr_search_params_logic methods take two arguments
  # @param [Hash] solr_parameters a hash of parameters to be sent to Solr (via RSolr)
  # @param [Hash] user_parameters a hash of user-supplied parameters (often via `params`)


  def tiny_url(uri, options = {})
    defaults = { :validate_uri => false }
    options = defaults.merge options
    return validate_uri(uri) if options[:validate_uri]
    return generate_uri(uri)
  end

  private

  def validate_uri(uri)
    confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix]
    if confirmed_uri.blank?
      return false
    else
      return true
    end
  end

  def generate_uri(uri)
    confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix]
    if !confirmed_uri.blank?
      escaped_uri = URI.escape("http://tinyurl.com/api-create.php?url=#{confirmed_uri}")
      uri_parsed = Net::HTTP.get_response(URI.parse(escaped_uri)).body
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
    begin_test = Integer(params[:range][:pub_date_facet][:begin]) rescue nil
    end_test = Integer(params[:range][:pub_date_facet][:end]) rescue nil
    if begin_test.nil? or begin_test < 0
      begin_test = 800
    end
    if end_test.nil? or end_test < 0
      end_test = Time.now.year + 2
    end
      if begin_test > end_test
        swap = end_test
        end_test = begin_test
        begin_test = swap
      end
      params[:range][:pub_date_facet][:begin] = begin_test
      params[:range][:pub_date_facet][:end] = end_test
  end


end
