module BlacklightCornell::CornellCatalog extend Blacklight::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include CornellCatalogHelper
  include ActionView::Helpers::NumberHelper

#  include ActsAsTinyURL
  SearchHistoryWindow = 12 # how many searches to save in session history

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :search_action_url
    before_filter :search_session, :history_session
    before_filter :delete_or_assign_search_session_params, :only => :index
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


  # get search results from the solr index
  def index
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )

    # @bookmarks = current_or_guest_user.bookmarks

    # params.delete("q_row")

    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    if params[:q_row].present?
      query_string = set_advanced_search_params(params)
    end
    # End of secondary parsing

    # Journal title search hack.
    if params[:search_field] == "journal title"
      if params[:f].nil?
        params[:f] = {}
      end
        params[:f] = {"format" => ["Journal"]}
        # unless(!params[:q])
        params[:q] = params[:q]
        params[:search_field] = "journal title"
    end
    # end of Journal title search hack

    (@response, @document_list) = get_search_results

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
  def solr_search_params(my_params = params || {})
    solr_parameters = {}

    solr_search_params_logic.each do |method_name|
      send(method_name, solr_parameters, my_params)
    end
    q_string = ""
    q_string2 = ""
    q_string_hold = ""
    q_stringArray = []
    q_string2Array = []
    opArray = []
    if !my_params[:boolean_row].nil?    
      for k in 0..my_params[:boolean_row].count - 1
         realsub = k + 1;
         n = realsub.to_s
         opArray[k] = my_params[:boolean_row][n.to_sym]
      end
      for i in 0..my_params[:q_row].count - 1
         if my_params[:op_row][i] == "phrase"
           newpass = '"' + my_params[:q_row][i] + '"' 
         else
           newpass = my_params[:q_row][i]
         end 
         pass_param = { my_params[:search_field_row][i] => my_params[:q_row][i]}
         returned_query = ParsingNesting::Tree.parse(newpass)
         newstring = returned_query.to_query(pass_param)
         holdarray = newstring.split('}')
         queryStart = " _query_:\"{!dismax"
         q_string << " _query_:\"{!dismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""
         q_string2 << ""
         q_string_hold << " _query_:\"{!dismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""
         fieldNames = blacklight_config.search_fields["#{my_params[:search_field_row][i]}"]
         if !fieldNames["solr_parameters"].nil?
            solr_stuff = fieldNames["solr_parameters"]
            field_name = solr_stuff[:"spellcheck.dictionary"]
            q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
            q_string2 << field_name << " = "
            q_string_hold << " spellcheck.dictionary=" + field_name + " qf=$" + field_name + "_qf pf=$" + field_name + "_pf"
         end
         if holdarray.count > 1
          if field_name.nil?
            field_name = 'all_fields'
          end

          for j in 1..holdarray.count - 1
              holdarray_parse = holdarray[j].split('_query_')
              holdarray[1] = holdarray_parse[0]
              if(j < holdarray.count - 1)
                    q_string_hold << "}" << holdarray[1] << " _query_:\\\"{!dismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
                    q_string << "}" << holdarray[1] << " _query_:\\\"{!dismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf" #}" << holdarray[1].chomp("\"") << "\""
                    q_string2 << holdarray[1]
              else
                    q_string_hold << "}" << holdarray[1] << "\\\""
                    q_string << "}" << holdarray[1] << "\\\""
                    q_string2 << holdarray[1] << " "
              end
          end
         else
                 q_string_hold << "}" << holdarray[1] << "\\\""
                 q_string << "}" << holdarray[1] << "\\\""
                 q_string2 << holdarray[1]
         end
         if i < my_params[:q_row].count - 1
           q_string_hold << " "
           q_string << " " <<  opArray[i] << " "
           q_string2 << " "
        end 
        q_stringArray << q_string_hold
        q_string2Array << q_string2
        q_string_hold = "";
        q_string2 = "";
      end
     
      test_q_string = groupBools(q_stringArray, opArray)
      test_q_string2 = groupBools(q_string2Array, opArray)
      if test_q_string == ""
        solr_parameters[:sort] = "score desc, title_sort asc"
      end
       solr_parameters[:q] = test_q_string
      params[:show_query] = test_q_string2
  end
  Rails.logger.info("Lafayette")
  return solr_parameters

 end

  def groupBools(q_stringArray, opArray)
     grouped = []
     newString = ""
     if !q_stringArray.nil?
       newString = q_stringArray[0];
       for i in 0..opArray.count - 1
  #        q_stringArray[i +1].gsub('"',"")
  #        newString = "(" + newString + " " + opArray[i] + " "+ q_stringArray[i + 1] + ") "
          newString = newString + " " + opArray[i] + " "+ q_stringArray[i + 1]
  #        else
  #           if opArray[i] == "OR"
  #            newString = newString + " OR " + q_stringArray[i + 1]
  #           else
  #            newString = newString + " NOT " + q_stringArray[i + 1]
  #           end
  #       end
       end
     else
   #    params[:sort] = ""
     end
     #newString = newString.gsub('"',"")
#     newString =  "_query_:{!dismax}bauhaus  AND ( _query_:{!dismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}architecture  NOT  _query_:{!dismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}graphic design )"
     return newString
  end

  def set_advanced_search_params(params)
         params["advanced_query"] = "yes"
         # Use :advanced_search param as trustworthy indicator of search type
         params[:advanced_search] = true
         counter = test_size_param_array(params[:q_row])
         if counter > 1
            query_string = massage_params(params)
             holdparams = []
             terms = []
             ops = 0
             params["op"] = []
             holdparams = query_string.split("&")
             for i in 0..holdparams.count - 1
                terms = holdparams[i].split("=")
                if (terms[0] == "op[]")
                  params["op"][ops] = terms[1]
                  ops = ops + 1
                else
                  params[terms[0]] = terms[1]
                  search_session[terms[0]] = terms[1]
                end
             end
             if holdparams.count > 2
               params["search_field"] = "advanced"
               params[:q] = query_string
               search_session[:q] = query_string
               search_session[:search_field] = "advanced"
             else
               params[:q] = params["q"]
               search_session[:q] = params[:q]
               params[:search_field] = params["search_field"]
               search_session[:search_field] = params[:search_field]
             end
             params["commit"] = "Search"
#             params["sort"] = "score desc, pub_date_sort desc, title_sort asc";
             params["action"] = "index"
             params["controller"] = "catalog"
       else
#            search_session = {}
            params.delete("advanced_query")
            query_string = parse_single(params)
            holdparams = query_string.split("&")
            for i in 0..holdparams.count - 1
              terms = holdparams[i].split("=")
              params[terms[0]] = terms[1]
              search_session[terms[0]] = terms[1]
              session[:search][:"#{terms[0]}"] = terms[1]
            end
           #  params[:q] = query_string
             params.delete("q_row")
             params.delete("op_row")
             params.delete("search_field_row")
             params["commit"] = "Search"
             params["action"] = "index"
             params["controller"] = "catalog"
       end
     return query_string
  end


  def massage_params(params)
    rowHash = {}
    opArray = []
    query_string = ""
    new_query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
    search_field_rowArray = params[:search_field_row]
    if query_rowArray.count > 1
#first row
       if query_rowArray[0] != ""
         new_query_string = parse_query_row(query_rowArray[0], op_rowArray[0])
         rowHash[search_field_rowArray[0]] = new_query_string
         new_query_string = ""
       end

       for i in 1..query_rowArray.count - 1
         n = i.to_s
         if query_rowArray[i] != ""
           new_query_string = parse_query_row(query_rowArray[i], op_rowArray[i])
           if rowHash.has_key?(search_field_rowArray[i])
              current_query = rowHash[search_field_rowArray[i]]
              new_query = " " << current_query << " " << params[:boolean_row][n.to_sym] << " " << new_query_string << " "
              rowHash[search_field_rowArray[i]] = new_query
           else
              rowHash[search_field_rowArray[i]] = new_query_string
              opArray << params[:boolean_row][n.to_sym]
           end
         end
       end
       opcount = 0;
       query_string_two = ""
       newArray = rowHash.flatten
       keywordscount = newArray.count / 2
       for i in 0..keywordscount -1
         if i < keywordscount - 1
          if opArray[i].nil?
            opArray[i] = 'AND'
          end
          query_string_two << newArray[i*2] << "=" << newArray[(i*2)+1] << "&op[]=" << opArray[i] << "&"
         else
          query_string_two << newArray[i*2] << "=" << newArray[(i*2)+1] << ""
         end
       end
       #account for some bozo not selecting different search_fields
       bozocheck = query_string_two.split("=")
       if bozocheck.count < 3
         query_string_two = "q=" + bozocheck[1] + "&search_field=" + bozocheck[0]
         params["search_field"] = bozocheck[0]
         params.delete("advanced_query")
       end
    end
   return query_string_two
  end

  def parse_query_row(query, op)
    splitArray = []
    returnstring = ""
    if op == "phrase"
      query.gsub!("\"", "\'")
#      returnstring << '"' << query << '"'
      returnstring = query
    else
      splitArray = query.split(" ")
      if splitArray.count > 1
         returnstring = splitArray.join(' ' + op + ' ')
      else
         returnstring = query
      end
    end
    return returnstring
  end


  def parse_single(params)
    query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
    search_field_rowArray = params[:search_field_row]
      for i in 0..query_rowArray.count - 1
         if query_rowArray[i] != ""
           query_string << "q="
           query_rowSplitArray = query_rowArray[i].split(" ")
           if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
             query_string << query_rowSplitArray[0] << " " << op_rowArray[i] << " "
             for j in 1..query_rowSplitArray.count - 2
               query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
             end
             query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << "&search_field=" << search_field_rowArray[i]
           elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
             query_rowArray[i].gsub!("\"", "\'")
             query_string << '"' << query_rowArray[i] << '"&search_field=' << search_field_rowArray[i]
             query_string << query_rowArray[i] << "&search_field=" << search_field_rowArray[i]
           else
             query_string << query_rowArray[i] << "&search_field=" << search_field_rowArray[i]
           end
         end
      end
     return query_string
  end

  def test_size_param_array(param_array)
    countit = 0
    for i in 0..param_array.count - 1
       unless param_array[i] == ""
        countit = countit + 1
       end
    end
    return countit
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
    def email
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      if request.post?
        if params[:to]
          url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}

          if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
            email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :location=> params[:location] }, url_gen_params)
          else
            flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
          end
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.blank')
        end

        unless flash[:error]
          email.deliver
          flash[:success] = "Email sent"
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
    def search_session
      session[:search] ||= {}
    end

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

       new_search = Search.create(:query_params => params_copy)
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
  




end
