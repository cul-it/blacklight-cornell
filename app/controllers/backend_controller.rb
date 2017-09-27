class BackendController < ApplicationController
  #include Blacklight::SolrHelper
  include Blacklight::SearchHelper

  def holdings
    begin 
      @holdings = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    rescue StandardError
      @holdings = {} 
      @holdings['condensed_holdings_full'] =  {}
    end
    begin 
      @holdings_detail = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_raw/#{params[:id]}"))[params[:id]]
    rescue StandardError
      @mholdings = {} 
    end
    @id = params[:id]
    resp, document = fetch (@id)
    if document['url_pda_display'].present?
      @holdings['condensed_holdings_full'].each do |chf|
        chf['location_name'] = ''
        chf['location_code'] = ''
      end
      @hide_status = true
    end

    session[:holdings] = @holdings
    session[:holdings_detail] = @holdings_detail
    render "backend/holdings", :layout => false
  end

  def holdings_short
    begin 
      @holdings = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    rescue StandardError
      @holdings = {} 
      @holdings['condensed_holdings_full'] = {} 
    end
    begin 
      @holdings_detail=JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{params[:id]}"))[params[:id]]
    rescue StandardError
      @holdings_detail = {} 
    end
    @id = params[:id]
    # logger.debug  "getting info for #{params[:id]} from"
    # logger.debug Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"
    # logger.debug @holdings
    # logger.debug session.inspect
    session[:holdings] = @holdings
    session[:holdings_detail] = @holdings_detail
    # logger.debug session.inspect
    render :json => @holdings_detail
    #render "backend/holdings", :layout => false
  end

  def holdings_shorthm
   #Accept-Encoding: gzip, deflate
    extheader = { 'Accept-Encoding' => 'gzip, deflate' }
    logger.debug "es287 #{__FILE__}:#{__LINE__} " + Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{params[:id]}"
    @mholdings_detail = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{params[:id]}",extheader))
    @mid = params[:id]
    logger.debug  "es287_debug #{__FILE__}:#{__LINE__} getting info (Multi bibid) for #{params[:id]} from"
    logger.debug Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{@mid}"
    logger.debug "es287_debug #{__FILE__}:#{__LINE__} @mholdings_detail = #{@mholdings_detail.inspect}"
    session[:holdings] = @holdings
    session[:holdings_detail] = @holdings_detail
    rendera = {};
    @bibids = params[:id].split('/').collect { |bibid| bibid.strip }
    @bibids.collect do |bibid|
      @holdings_detail = @mholdings_detail[bibid]
      @id = bibid
      rendera[bibid] = render_to_string "backend/holdings_short", :layout => false
    end
    render  :json => rendera, :layout => false
  end


  def holdings_shorth
    @holdings = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @holdings_detail = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{params[:id]}"))[params[:id]]
    @id = params[:id]
    # logger.debug  "getting info for #{params[:id]} from"
    # logger.debug Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"
    # logger.debug @holdings
    # logger.debug session.inspect
    session[:holdings] = @holdings
    session[:holdings_detail] = @holdings_detail
    # logger.debug session.inspect
    #render :json => @holdings_detail
    render "backend/holdings_short", :layout => false
  end

  def holdings_mail

    @holdings = JSON.parse(HTTPClient.get_content("http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @id = params[:id]

    render "backend/_holdings_mail", :layout => false
  end

  def feedback_mail
    session[:feedback_form_name] = params["name"]
    session[:feedback_form_email] = params["email"]
    begin
      FeedbackNotifier.send_feedback(params).deliver

      render :text => "success"
    rescue Exception => e
      logger.info e.backtrace
      render :text => "failure"
    end
  end

  def retrieve_book_jackets
    isbns = params["isbns"].listify
    results = {}
    hc = HTTPClient.new

    begin
      isbns.each do |isbn|
        unless results[isbn]
          query_url = 'http://books.google.com/books/feeds/volumes'
          # logger.info("retrieving #{query_url}?q=isbn:#{isbn}")
          xml = Nokogiri::XML(hc.get_content(query_url, :q => "isbn:" + isbn))
          image_node = xml.at_css("feed>entry>link[@type^='image']")
          results[isbn] = image_node.attributes["href"].content.gsub(/zoom=./,"zoom=1") if image_node
        end
      end
    rescue Exception => e
      logger.warn("exception retrieving google book search: #{e.message}")
    end

    render :json => results
  end

#  def blacklight_solr
#    @solr ||=  RSolr.connect(blacklight_solr_config)
#  end

#  def blacklight_solr_config
#    Blacklight.solr_config
#  end

  # This acts as a receiver for a JavaScript notification that a user has dismissed
  # the ie9-only warning that appears at the top of catalog pages. We want to
  # remember that so that the warning doesn't keep appearing during the user's
  # session. (This only affects users on IE9 browsers)
  def dismiss_ie9_warning

    respond_to do |format|
      format.js { render nothing: true }
    end

    session[:hide_ie9_warning] = true
  end

  # The route /backend/cuwebauth should exist and be protected by CUWebAuth.
  # This corresponding method simply sets a session variable with the netid
  # and sends you back to wherever you came from.
  def authenticate_cuwebauth
    semail = request.env['REMOTE_USER']
    u = User.where(email: semail).first
    if u
      @user = u
    else
      @user = User.new(email: semail)
      @user.save!
    end
    sign_in :user, @user
    session[:cu_authenticated_user] = semail 
    if session[:cu_authenticated_user].present?
      rp = session[:cuwebauth_return_path] ? session[:cuwebauth_return_path] : root_path
      redirect_to rp, :alert => "You are logged in as #{semail}"
    else
      redirect_to rp, :alert => "Authentication failed"
    end
  end

end
