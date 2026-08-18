class BackendController < ApplicationController

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
    @mholdings_detail = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{params[:id]}",extheader))
    @mid = params[:id]
    # :nocov:
      logger.debug Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_short/#{@mid}"
    # :nocov:
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

end
