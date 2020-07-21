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
#  include ActsAsTinyURL
Blacklight::Catalog::SearchHistoryWindow = 12 # how many searches to save in session history


  def set_return_path
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    op = request.original_fullpath
    # if we headed for the login page, should remember PREVIOUS return to.
    if op.include?('logins') && !session[:cuwebauth_return_path].blank?
      op = session[:cuwebauth_return_path]
    end
    op.dup.sub!('/range_limit','')
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  original = #{op.inspect}")
    refp = request.referer
    refp =""
    refp.sub!('/range_limit','') unless refp.nil?
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  referer path = #{refp}")

#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << "params " + params.inspect
msg << "op " + op.inspect
msg << "request " + request.original_fullpath.inspect
msg << '******************'
puts msg.to_yaml
Rails.logger.level = save_level
#*******************

    session[:cuwebauth_return_path] =
      if (params['id'].present? && params['id'].include?('|'))
        '/bookmarks'
      elsif (op.include?('/book_bags/email'))
        "/book_bags/email"
      elsif (params['id'].present? && op.include?('email'))
        "/catalog/#{params[:id]}"
      elsif (params['id'].present? && op.include?('unapi'))
         refp
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
#    before_action :add_cjk_params_logic
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

  # get search results by oclc number
  #
  #{"utf8"=>"✓", "advanced_query"=>"yes", "omit_keys"=>["page"], "params"=>{"advanced_query"=>"yes"}, "q_row"=>["(OCoLC)25367820", ""], "op_row"=>["phrase", "AND"], "search_field_row"=>["publisher number/other identifier", "all_fields"], "boolean_row"=>{"1"=>"AND"}, "sort"=>"score desc, pub_date_sort desc, title_sort asc", "search_field"=>"advanced", "commit"=>"Search"}
  #"q_row"=>["(OCoLC)25367820", ""], "op_row"=>["phrase", "AND"], "search_field_row"=>["publisher number/other identifier"
  #http://es287-dev.library.cornell.edu:8988/catalog?utf8=%E2%9C%93&advanced_query=yes&omit_keys%5B%5D=page&params%5Badvanced_query%5D=yes&q_row%5B%5D=%28OCoLC%2925367820&op_row%5B%5D=phrase&search_field_row%5B%5D=publisher+number%2Fother+identifier&boolean_row%5B1%5D=AND&q_row%5B%5D=&op_row%5B%5D=AND&search_field_row%5B%5D=all_fields&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&search_field=advanced&commit=Search
  #http://es287-dev.library.cornell.edu:8988/catalog?utf8=%E2%9C%93&omit_keys%5B%5D=page&params%5Badvanced_query%5D=yes&q_row%5B%5D=970658422&op_row%5B%5D=phrase&search_field_row%5B%5D=publisher+number%2Fother+identifier&boolean_row%5B1%5D=AND&q_row%5B%5D=&op_row%5B%5D=AND&search_field_row%5B%5D=all_fields&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&search_field=advanced&commit=Search
  def oclc_request
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{params[:id].inspect}")
    oid = params[:id]
    ActionController::Parameters.permit_all_parameters = true
    zparams = ActionController::Parameters.new(utf8: "✓", :boolean_row => {"1"=>"AND"}, q_row: ["(OCoLC)#{oid}", ""], op_row: ["phrase", "phrase"], search_field_row: ["publisher number/other identifier", "publisher number/other identifier"], sort: "score desc, pub_date_sort desc, title_sort asc", search_field: "advanced", advanced_query: "yes", commit: "Search", controller: "catalog", action: "index")
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} zparams = #{zparams.inspect}"
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.to_unsafe_h.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.to_unsafe_h.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )
    (@response, deprecated_document_list) = search_service.oclc_search_results(zparams)
    @document_list = deprecated_document_list
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} response = #{@response[:responseHeader].inspect}"
    num = @response["response"]["numFound"]
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} num = #{num.inspect}"
    if num == 1
      target = @document_list[0].response["response"]["docs"][0]["id"]
      logger.debug "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} target = #{target.inspect}"
      redirect_to(root_url() + "/request/#{target}")
    elsif num >  1
      logger.warn  "WARN: #{__FILE__}:#{__LINE__}:#{__method__} oclc id does not map to uniquid  = #{oid.inspect}"
      flash.now.alert = "The OCLC ID #{oid.inspect} does not map to a unique identifier."
      respond_to do |format|
        format.html { render :text => 'OCLCd does not map to unique record', :status => '404' }
      end
    else
      logger.warn  "WARN: #{__FILE__}:#{__LINE__}:#{__method__} oclc id not found = #{oid.inspect}"
      flash.now.alert = "The OCLC ID #{oid.inspect} was not found."
      respond_to do |format|
        format.html { render :text => 'Not Found', :status => '404' }
      end
    end
  end

  # get search results from the solr index
  def index
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
    # set_bag_name
    # make sure we are not going directly to home page
   if !params[:qdisplay].nil?
     params[:qdisplay] = ''
   end
   search_session[:per_page] = params[:per_page]
    temp_search_field = ''
    journal_titleHold = ''
    if (!params[:range].nil?)
        check_dates(params)
    end
    temp_search_field = ''
    if  !params[:q].blank? and !params[:search_field].blank? # and !params[:search_field].include? '_cts'
      if params[:q].include?('%2520')
        params[:q].gsub!('%2520',' ')
      end
      if params[:q].include?('%2F') or params[:q].include?('/')
        params[:q].gsub!('%2F','')
        params[:q].gsub!('/','')
      end
      if params[:search_field] == 'isbn%2Fissn' or params[:search_field] == 'isbn/issn'
        params[:search_field] = 'isbnissn'
      end
      if params["search_field"] == "journal title"
        journal_titleHold = "journal title"
#        params[:f] = {'format' => ['Journal/Periodical']}
      end
       params[:q] = sanitize(params)
       if params[:search_field] == 'call number' and !params[:q].include?('"')
         tempQ = params[:q]
       end
      # check_params(params)
       if !tempQ.nil?
         params[:qdisplay] = tempQ
       end
    else
      if params[:q].blank?
        temp_search_field = params[:search_field]
      else
        if params[:search_field].nil?
          params[:search_field] = 'quoted'
        end
        check_params(params)
      end
     if params[:q_row] == ["",""]
       params.delete(:q_row)
     end
    end
    if !params[:search_field].nil?
     if !params[:q].nil? and !params[:q].include?(':') and params[:search_field].include?('cts')
       params[:q] = params[:search_field] + ':' + params[:q]
     end
    end
    if !params[:q].nil?
     if params[:q].include?('_cts')
       display = params[:q].split(':')
       params[:q] = display[1]
     end
     end
      #params[:mm] = "100"
      params[:mm] = "1"
 #      params[:q] = '"journal of parasitology"'
 #     params[:search_field] = 'quoted'
    #params[:sort]= ''
    #params = {"utf8"=>"✓", "controller"=>"catalog", "action"=>"index", "q"=>"(+title:100%) OR title_phrase:\"100%\"", "search_field"=>"title", "qdisplay"=>"100%"}
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{params.inspect}"
   #params[:q] = '(+title_quoted:"A news" +title:Reporter)'
#    params[:search_field] = 'advanced'
   #params[:q] = '(water)'
    (@response, deprecated_document_list) = search_service.search_results session["search_limit_exceeded"]
    @document_list = deprecated_document_list
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} response = #{@response[:responseHeader].inspect}"
    #logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} document_list = #{@document_list.inspect}"
    if temp_search_field != ''
      params[:search_field] = temp_search_field
    end
    if journal_titleHold != ''
      params[:search_field] = journal_titleHold
    end
    if params[:search_field] == 'author_quoted'
      params[:search_field] = 'author/creator'
    end
    if @response[:responseHeader][:q_row].nil?
#     params.delete(:q_row)
#     params[:q] = @response[:responseHeader][:q]
#     params[:search_field] = ''
#     params[:advanced_query] = ''
#     params[:commit] = "Search"
#     params[:controller] = "catalog"
#     params[:action] = "index"
    end
    if params.nil? || params[:f].nil?
      @filters = []
    else
      @filters = params[:f] || []
    end

   # clean up search_field and q params.  May be able to remove this
  #  cleanup_params(params)

    @expanded_results = {}
    ['worldcat', 'summon'].each do |key|
      @expanded_results [key] =  { :count => 0 , :url => '' }
    end
    # Expand search only under certain conditions
    tmp = BentoSearch::Results.new
    if !(params[:search_field] == 'call number')
    if expandable_search?
      searcher = BentoSearch::ConcurrentSearcher.new(:summon, :worldcat)
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
    @controller = self
    if session["search_limit_exceeded"]
      flash.now.alert = I18n.t('blacklight.search.search_limit_exceeded')
    end
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json { render json: { response: { document: deprecated_document_list } } }
    end

     if !params[:q_row].nil?
       params[:show_query] = make_show_query(params)
       search_session[:q] = params[:show_query]
     end

    if !params[:qdisplay].blank?
      params[:q] = params[:qdisplay]
      search_session[:q] = params[:show_query]
#      params[:q] = qparam_display
      search_session[:q] = params[:q]
 #     params[:sort] = "score desc, pub_date_sort desc, title_sort asc"
    end

  end


  # get single document from the solr index
  def show
    @response, @document = search_service.fetch params[:id]
    @documents = [ @document ]
    # set_bag_name
    logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{params.inspect}"
    respond_to do |format|
      format.endnote_xml  { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.endnote  { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.html {setup_next_and_previous_documents}
      format.rss  { render :layout => false }
      format.ris      { render 'ris', :layout => false }
      #format.ris      { render "ris", :layout => false }
      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
         format.send(format_name.to_sym) { render :body => @document.export_as(format_name), :layout => false }
      end

    end
  end

  def setup_next_and_previous_documents

    query_params = session[:search] ? session[:search].dup : {}
#    if  !query_params[:q].blank? and !query_params[:search_field].blank? # and !params[:search_field].include? '_cts'
#       check_params(query_params)
#    else
#      if query_params[:q].blank?
#        temp_search_field = query_params[:search_field]
#        query_params[:search_field] = 'all_fields'
#          end
#    end

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
          render :json => search_service.opensearch_response
        end
      end
    end

    # citation action
    def citation
      @response, @documents = search_service.fetch params[:id]
      @documents = [ @documents ]
      respond_to do |format|
        format.html { render :layout => false }
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
      fmt = params[:format]
      Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  #{__method__} = #{fmt}")
      respond_to do |format|
        format.endnote_xml { render "show.endnote_xml" ,layout: false }
        format.endnote     { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
        format.ris         { render 'ris', :layout => false }
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

    # Now handled in the sms_action above and set up by the add_show_tools_partial config setting in the catalog controller.
    # So this code can just get deleted at some point. -- tlw72
    # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    # def sms
    #  (@response, deprecated_document_list) = search_service.fetch(params[:id])
    #  if request.post?
    #    url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}
    #    tinyPass = request.protocol + request.host_with_port + solr_document_path(params['id'])
    #    tiny = tiny_url(tinyPass)
    #    if params[:to]
    #      phone_num = params[:to].gsub(/[^\d]/, '')
    #      unless params[:carrier].blank?
    #        if phone_num.length != 10
    #          flash[:error] = I18n.t('blacklight.sms.errors.to.invalid', :to => params[:to])
    #        else
    #          email = RecordMailer.sms_record(@documents, {:to => phone_num, :carrier => params[:carrier], :callnumber => params[:callnumber], :location => params[:location], :tiny => tiny}, url_gen_params)
    #        end
    #
    #      else
    #        flash[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
    #      end
    #    else
    #      flash[:error] = I18n.t('blacklight.sms.errors.to.blank')
    #    end
    #
    #    unless flash[:error]
    #      email.deliver
    #      flash[:success] = 'Text sent'
    #      redirect_to facet_catalog_path(params['id']) unless request.xhr?
    #    end
    #  end
    #  unless !request.xhr? && flash[:success]
    #    respond_to do |format|
    #      format.js { render :layout => false }
    #      format.html
    #    end
    #  end
    #end


    def librarian_view
      @response, @document = search_service.fetch params[:id]

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
    confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix] ||
                    uri[/^(http|https):\/\/localhost(:[0-9]{1,5})?(\/.*)?$/ix]
    if confirmed_uri.blank?
      return false
    else
      return true
    end
  end

  def generate_uri(uri)
    Appsignal.increment_counter('item_sms', 1)
    confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix] ||
                    uri[/^(http|https):\/\/localhost(:[0-9]{1,5})?(\/.*)?$/ix]
    if !confirmed_uri.blank?
      uri_parsed = confirmed_uri
      shorten = Rails.application.config.url_shorten
      logger.info "URL shortener:  #{__FILE__}:#{__LINE__}:#{__method__} #{shorten.pretty_inspect}"
      if !shorten.empty?
        escaped_uri = URI.escape("#{shorten}#{confirmed_uri}")
        begin
          uri_parsed = Net::HTTP.get_response(URI.parse(escaped_uri)).body
          #uri_parsed = Net::HTTP.get_response(URI.parse(escaped_uri),{:read_timeout => 10}).body
        rescue StandardError  => e
          logger.error "URL shortener error:  #{__FILE__}:#{__LINE__}:#{__method__} #{e} #{shorten}"
          Appsignal.send_error(e)
          uri_parsed = confirmed_uri
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

def check_params(params)
     qparam_display = ''
     fieldname = ''

     # Journal title search hack.
     if params[:search_field].nil?
       params[:search_field] = 'all_fields'
     end
     if (params[:search_field].present? and params[:search_field] == 'journal title') or (params[:search_field_row].present? and params[:search_field_row].index('journal title'))
       if params[:f].nil?
         params[:f] = {'format' => ['Journal/Periodical']}
       end
       params[:f][:format] = ['Journal/Periodical']
       # unless(!params[:q])
       #params[:q] = params[:q]
       if (params[:search_field_row].present? and params[:search_field_row].index('journal title'))
         params[:search_field] = 'advanced'
       else
         params[:search_field] = 'title'
       end
       search_session[:f] = params[:f]
     end
     fieldname = ''
     if params[:search_field] == 'call number'
       fieldname = 'lc_callnum'
     else
       if params[:search_field] == 'author/creator' or params[:search_field] == 'author'
         fieldname = 'author'
       else
         if params[:search_field] == 'all_fields'
           fieldname = ''
         else
           if params[:search_field] == 'publisher number/other identifier'
             fieldname = 'number'
             params[:search_field] = 'number'
           else
            fieldname = params[:search_field]
           end
         end
       end
     end
     # end of Journal title search hack
     logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} params = #{params.inspect}"
     #quote the call number
     if params[:search_field] == 'call number'
        params[:search_field] = 'lc_callnum'
        if !params[:q].nil?
          search_session[:q] = params[:q]
    #      params[:qdisplay] = params[:q]
          if !params[:q].include?('"')
            params[:q] = '"' << params[:q] << '"'
          end
         # params[:q] = '(lc_callnum:' << params[:q] << ')' #OR lc_callnum:' << params[:q]
        else
          params[:q] =  '' or params[:q].nil?
          params[:search_field] = 'all_fields'
        end
     end
     if params[:search_field] == "title_starts"
       params[:qdisplay] = params[:q]
       params[:q] = '"' + params[:q] + '"'
     else
       if (params[:search_field] != 'journal title ' and params[:search_field] != 'call number')# or params[:action] == 'range_limit'
         qparam_display = params[:q]
         params[:qdisplay] = params[:q]
      #   params[:q] = parseQuoted(params[:q])
         if !params[:search_field].include?('browse')
          qarray = params[:q].split(' ')
         else
          qarray = [params[:q]]
         end
          if !params[:q].nil? and (params[:q].include?('OR') or params[:q].include?('AND') or params[:q].include?('NOT'))
             params[:q] = params[:q]
          else
             if (!params[:q].nil? and !params[:q].include?('"') and !params[:q].blank?)# or params[:action] == 'range_limit'
                params[:q] = '('
                if qarray.size == 1
                   if qarray[0].include?(':')
                     qarray[0].gsub!(':','\:')
                   end
                   if fieldname == ''
                      params[:q] << "+" << qarray[0] << ') OR phrase:"' << qarray[0] << '"'
                   else
                      if (fieldname != "title" and fieldname != "subject") and fieldname != "title_starts" and fieldname != 'lc_callnum'
                        params[:q] << '+' << fieldname << ":" << qarray[0] << ') OR ' << fieldname + "_phrase" << ':"' << qarray[0] << '"'
                      else
                       #This should be cleaned up next week when I start removing redundancies and cleaning up code
                        if fieldname != "title_starts"
                          if fieldname == "number" or fieldname == "title"
                           params[:q] << '+' << fieldname << ':' << qarray[0] << ') OR ' << fieldname + '_phrase:"' << qarray[0] << '"'
                          else
                           params[:q] << '+' << fieldname << ':' << qarray[0] << ') OR ' << fieldname << ':"' << qarray[0] << '"'
                          end
                        else
                           if qarray[0].include?('"')
                             qarray[0] = qarray[0].gsub!('"','')
                           end
                           params[:q] << '+' << fieldname << ':"' << qarray[0] << '")'
                        end
                      end
                   end
                else
                   qarray.each do |bits|
                      if bits.include?(':')
                        bits.gsub!(':','\\:')
                      end
                      if fieldname == ''
                         params[:q] << '+' << bits << ' '
                      else
                         params[:q] << '+' << fieldname << ':' << bits << ' '
                      end
                   end
                   if fieldname == ''
                      params[:q] << ') OR phrase:"' << qparam_display << '"'
                   else
                     if fieldname == "title"
                      params[:q] << ') OR ' << fieldname + "_phrase" << ':"' << qparam_display << '"'
                     else
                      params[:q] << ') OR ' << fieldname << ':"' << qparam_display << '"'
                     end
                   end
                end
             else
               if params[:q].first == '"' and params[:q].last == '"' and !params[:search_field].include?('browse')
            #     if (fieldname == 'title' or fieldname == 'number' or fieldname == 'subject') and fieldname != ''
                 if  fieldname != '' and fieldname != "lc_callnum" and !fieldname.include?('_cts')
                    params[:q] = params[:q]
                    params[:search_field] = fieldname << '_quoted'
                    params[:q] = params[:search_field] + ':' + params[:q]
                 else
                   if fieldname == ''
                    params[:q] = "quoted:" + params[:q]
                    params[:search_field] = 'quoted'
                   end
                   if fieldname == "lc_callnum"
                     params[:qdisplay] = params[:q]
                 #    params[:q].gsub!('"','')
                     params[:q] = '(+lc_callnum:' + params[:q] + ') OR lc_callnum:' + params[:q] + ''
                   end
                   if fieldname.include?('_cts')
                     params[:qdisplay] = params[:q]
                     params[:q] = fieldname + ':' + params[:q]
                   end
                 end
               else
                 qarray = separate_quoted(params[:q])
                 params[:q] = ''
                 qarray.each do |bits|
                   if bits.include?(':')
                     bits.gsub!(':','\\:')
                   end
                   if bits.first == '"'
                      #bits = bits + '"'
                      if fieldname == ''
                       params[:q] << '+quoted:' + bits + ' '
                      else
                        if !params[:search_field].include?('browse')
                         params[:q] << '+' + fieldname + '_quoted:' + bits + ' '
                        end
                      end
                   else
                     if fieldname == ''
                       params[:q] << '+' + bits + ' '
                     else
                       params[:q] << '+' + fieldname + ':' + bits + ' '
                     end
                   end
                 end
               end
               if params[:q].nil? or params[:q].blank?
                 params[:q] = qparam_display
               end
             end
             if params[:search_field].include?('browse')
               params[:q] = params[:search_field] + ":" + params[:q]
             end
         end
      end
    end
    #    if params[:search_field] = "call number"
    #      params[:q] = "\"" << params[:q] << "\""
    #    end
    #    params[:q] = ' _query_:"{!edismax qf=$subject_qf pf=$subject_pf}bauhaus"  AND  _query_:"{!edismax qf=$title_qf pf=$title_pf}history"  OR  _query_:"{!edismax qf=$all_fields_qf pf=$all_fields_pf}design"'
    #    params[:q] = '((notes_qf:"English, German, Italian, Latin, or Portugese" AND "Bibliotheca Instituti Historici") OR ("turkeys" NOT "spam"))'
 #   if params[:search_field] == "all_fields" and params[:q]
#      params[:search_field] = 'all_fields'
#    end

    #    if params[:q].blank?
    #      params[:q] = '*'
    #    end
#    params[:q] = '(+\\\"combined heat and power\\\") AND (+cogeneration)'
#    params[:q] = "(title:100%) OR title_phrase:\"100%\""
   return params
  end

  def separate_quoted(string)
    #string = "this \"is what not\" quoted \"but this is\""
    if string.count('"').odd?
      if string[-1] == '"'
        string = string[0..-2]
      else
        string = string + '"'
      end
    end
    tempStringArray = string.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    return tempStringArray
  end


  def cleanup_params(params)
    qparam_display = params[:qdisplay]
    if !qparam_display.nil?
      if qparam_display.start_with?('"') and qparam_display.end_with?('"')
        qparam_display = qparam_display[1..-1]
      end
    end
    query_string = params[:q]
    fieldname = ''
    if params[:search_field] == 'journal title'
       if params[:q].nil?
         params[:search_field] = ''
       end
    end

    if params[:q_row].present?
       if params[:q].nil?
        params[:q] = query_string
       end
    else
        if params[:q].nil?
          if !params[:search_field].nil?
             params.delete(:search_field)
         end
        else
          if params[:q].include?('_quoted:') or params[:q].include?('+quoted')
            params[:q].gsub!('(','')
            params[:q].gsub!(')','')
            holdQ = params[:q].split(':')
            params[:q] = holdQ[1]
          end
          if params[:search_field].nil?
            params[:search_field] = 'all_fields'
          end
          if params[:search_field].include?('quoted')
            params[:search_field].gsub!('quoted','')
            if params[:search_field].include?('_')
              params[:search_field].gsub!('_','')
            end
          end
        end
    end
    if params[:search_field] == 'call number'
      if !params[:q].nil? and params[:q].include?('"')
        params[:q] = params[:q].gsub!('"','')
      end
    end
 #   if params[:search_field] == 'all_fields'
 #     params[:search_field] = ''
 #   end
    if params[:search_field] == 'lc_callnum'
      params[:search_field] = 'call number'
    end
    if params[:search_field] == 'number'
      params[:search_field] = 'publisher number/other identifier'
    end
    # end of cleanup of search_field and q params
    return params
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

  def parseQuoted(q)
    if q.first == '"' and q.last == '"'
      return q
    else
      howmany = q.count('"')
      if !howmany.even?
        q = q + '"'
      end
    end
    return q
  end


#   def set_bag_name

# #******************
# save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
# Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
# msg = ['******************' + " #{__method__}"]
# msg << "current_user: " + current_user.email.to_s unless current_user.nil?
# msg << "Bookbag enabled: " + BookBag.enabled?.to_s
# msg << '******************'
# puts msg.to_yaml
# Rails.logger.level = save_level
# #*******************

#     user_session[:bookbag_count] = nil unless user_session.nil?
#      if current_user && BookBag.enabled?
#        @id = current_user.email
#        @bb = BookBag.new
#        @bb.set_bagname("#{@id}-bookbag-default")
#        user_session[:bookbag_count] = @bb.count
#      end
#    end

end
