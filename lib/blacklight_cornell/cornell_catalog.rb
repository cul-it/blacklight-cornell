#encoding: UTF-8
module BlacklightCornell::CornellCatalog extend Blacklight::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include CornellCatalogHelper
  include ActionView::Helpers::NumberHelper
  include CornellParamsHelper
#  include ActsAsTinyURL
  SearchHistoryWindow = 12 # how many searches to save in session history

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :search_action_url
    before_filter :search_session, :history_session
    before_filter :delete_or_assign_search_session_params, :only => :index
    before_filter :add_cjk_params_logic
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

  def search_action_url
    url_for(:action => 'index', :only_path => true)

  end

  def add_cjk_params_logic
    CatalogController.solr_search_params_logic << :cjk_query_addl_params
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
    qparam_display = ""
    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    if params[:q_row].present?
      query_string = set_advanced_search_params(params)
    end
    # End of secondary parsing
    
    # Journal title search hack.
    if (params[:search_field].present? and params[:search_field] == "journal title") or (params[:search_field_row].present? and params[:search_field_row].index("journal title"))
      if params[:f].nil?
        params[:f] = {"format" => ["Journal/Periodical"]}
      end
        params[:f].merge("format" => ["Journal/Periodical"])
        # unless(!params[:q])
#        params[:q] = params[:q]
        if (params[:search_field_row].present? and params[:search_field_row].index("journal title"))
          params[:search_field] = "advanced"
        else
          params[:search_field] = "journal title"
        end
        search_session[:f] = params[:f]
    end
    
    #quote the call number
    if params[:search_field] == "call number"
      if !params[:q].nil? and !params[:q].include?('"')
        params[:q] = '"' << params[:q] << '"'
        search_session[:q] = params[:q]
      end        
    end
    
    if params[:search_field] != "journal title " and params[:search_field] != "call number"
     if !params[:q].nil? and (params[:q].include?('OR') or params[:q].include?('AND') or params[:q].include?('NOT'))
       params[:q] = params[:q]
     else 
      if !params[:q].nil? and !params[:q].include?('"') and !params[:q].blank? 
          qparam_display = params[:q]
          qarray = params[:q].split
          params[:q] = "("
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
          params[:q] = params[:q]
        end
      end
     end
    end
    # end of Journal title search hack
    
#    if params[:search_field] = "call number"
#      params[:q] = "\"" << params[:q] << "\""
#    end
    if num_cjk_uni(params[:q]) > 0
      cjk_query_addl_params({}, params)
    end
#    Rails.logger.info("BEEVIS = #{params[:q]}")

    (@response, @document_list) = get_search_results
    
    if !qparam_display.blank?
      params[:q] = qparam_display
      search_session[:q] = params[:q]
    end
    if params.nil? || params[:f].nil?
      @filters = []
    else
      @filters = params[:f] || []
    end

    # clean up search_field and q params.  May be able to remove this
    if params[:search_field] == "journal title"
       if params[:q].nil?
         params[:search_field] = ""
       end
    end

    if params[:q_row].present?
       if params[:q].nil?
        params[:q] = query_string
       end
    else
        if params[:q].nil?
          params[:q] = query_string
        end
    end
    
    if params[:search_field] == "call number"
      if !params[:q].nil? and params[:q].include?('"')
        params[:q] = params[:q].gsub!('"','')
      end
    end
    # end of cleanup of search_field and q params

    # Expand search only under certain conditions
    if expandable_search?
      searcher = BentoSearch::MultiSearcher.new(:summon, :worldcat)
      searcher.search(params[:q], :per_page => 1)

      @expanded_results = {}

      searcher.results.each_pair do |key, result|
        source_results = {
          :count => number_with_delimiter(result.total_items),
          :url => BentoSearch.get_engine(key).configuration.link + params[:q],
        }
        @expanded_results[key] = source_results
      end
    end

    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
  end


    # get single document from the solr index
    def show
      @response, @document = get_solr_response_for_doc_id
      respond_to do |format|
        format.html {setup_next_and_previous_documents}

        # Add all dynamically added (such as by document extensions)
        # export formats.
        @document.export_formats.each_key do | format_name |
          # It's important that the argument to send be a symbol;
          # if it's a string, it makes Rails unhappy for unclear reasons.
          format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
        end

      end
    end

    # updates the search counter (allows the show view to paginate)
    def update
      adjust_for_results_view
      session[:search][:counter] = params[:counter]
      redirect_to :action => "show"
    end

    # displays values and pagination links for a single facet field
    def facet
      @pagination = get_facet_pagination(params[:id], params)

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end

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
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    end
    # grabs a bunch of documents to export to endnote
    def endnote
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      respond_to do |format|
        format.endnote { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
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
##          redirect_to catalog_path(params['id']) unless request.xhr?
##        end
##      end

##      unless !request.xhr? && flash[:success]
##        respond_to do |format|
##          format.js { render :layout => false }
##          format.html
##        end
##      end
##    end

    # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def sms
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      if request.post?
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}
        tinyPass = request.protocol + request.host_with_port + catalog_path(params['id'])
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
          flash[:success] = "Text sent"
          redirect_to catalog_path(params['id']) unless request.xhr?
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
      @response, @document = get_solr_response_for_doc_id

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
    def setup_next_and_previous_documents
      setup_previous_document
      setup_next_document
    end

    # gets a document based on its position within a resultset
    def setup_document_by_counter(counter)
      return if counter < 1 || session[:search].blank?
      search = session[:search] || {}
      get_single_doc_via_search(counter, search)
    end

    def setup_previous_document
      @previous_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i - 1) : nil
    end

    def setup_next_document
      @next_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i + 1) : nil
    end

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
        session[:search][key.to_sym] = value unless ["commit", "counter"].include?(key.to_s) ||
          value.blank?
      end
    end

    # Saves the current search (if it does not already exist) as a models/search object
    # then adds the id of the serach object to session[:history]
    def save_current_search_params
      # If it's got anything other than controller, action, total, we
      # consider it an actual search to be saved. Can't predict exactly
      # what the keys for a search will be, due to possible extra plugins.
      return if (search_session.keys - [:controller, :action, :total, :counter, :commit ]) == []
      params_copy = search_session.clone # don't think we need a deep copy for this
      params_copy.delete(:page)

      unless @searches.collect { |search| search.query_params }.include?(params_copy)

       #new_search = Search.create(:query_params => params_copy)
       logger.debug "es287_debug file:#{__FILE__}:#{__LINE__}:query_params=#{params_copy}\n"

       new_search = Search.new
       new_search.assign_attributes({:query_params => params_copy}, :without_protection => true)
       new_search.save

        session[:history].unshift(new_search.id)
        # Only keep most recent X searches in history, for performance.
        # both database (fetching em all), and cookies (session is in cookie)
        session[:history] = session[:history].slice(0, Blacklight::Catalog::SearchHistoryWindow )
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
      if params[:results_view] == "false"
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
         logger.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
          raise exception
        end

        logger.error exception

        flash[:notice] = flash_notice
        redirect_to root_path
      end
    end

    # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
    def invalid_solr_id_error
      if Rails.env == "development"
        render # will give us the stack trace
      else
        flash[:notice] = I18n.t('blacklight.search.errors.invalid_solr_id')
        params.delete(:id)
        index
        render "index", :status => 404
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
  def sortby_title_when_browsing solr_parameters, user_parameters
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
      solr_parameters[:sort] = browsing_sortby.field
    end
  end

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

  def cjk_mm_qs_params(str)
 #   cjk_mm_val = []
    num_uni = num_cjk_uni(str)
    if num_uni > 2 
      num_non_cjk_tokens = str.scan(/[[:alnum]]+/).size
      if num_non_cjk_tokens > 0
        lower_limit = cjk_mm_val[0].to_i
        mm = (lower_limit + num_non_cjk_tokens).to_s + cjk_mm_val[1, cjk_mm_val.size]
        {'mm' => mm, 'qs' => 0}
      else
        {'mm' => cjk_mm_val, 'qs' => 0}
      end
    else
      {}
    end
  end
  
  def cjk_query_addl_params(solr_params, params)
    if params && params.has_key?(:q)
      q_str = (params[:q] ? params[:q] : '')
      num_uni = num_cjk_uni(q_str)
      if num_uni > 2
        solr_params.merge!(cjk_mm_qs_params(q_str))
#        Rails.logger.info("SPEZ = #{solr_params}")
      end
      
      if num_uni > 0
        case params[:search_field]
          when 'all_fields', nil
           solr_params[:q] = "{!qf=$qf pf=$pf pf3=$pf3 pf2=$pf2}#{q_str}"
          when 'title'
           solr_params[:q] = "{!qf=$title_qf pf=$title_pf pf3=$title_pf3 pf2=$title_pf2}#{q_str}"
          when 'author/creator'
           solr_params[:q] = "{!qf=$author_qf pf=$author_pf pf3=$pf3_author_pf3 pf2=$author_pf2}#{q_str}"
          when 'journal title'
           solr_params[:q] = "{!qf=$journal_qf pf=$journal_pf pf3=$journal_pf3 pf2=$journal_pf2}#{q_str}"
          when 'subject'
           solr_params[:q] = "{!qf=$subject_qf pf=$subject_pf pf3=$subject_pf3 pf2=$subject_pf2}#{q_str}"
        end
      end
    end
  end

  def num_cjk_uni(str)
    if str
      str.scan(/\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/).size
    else
      0
    end
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
