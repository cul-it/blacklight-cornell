
class RequestController < ApplicationController
  include Blacklight::Catalog
  include  Blacklight::Solr
  include Blacklight::SolrHelper

# Blacklight uses #search_action_url to figure out the right URL for
#   # the global search box
  def search_action_url
         catalog_index_url
  end
  helper_method :search_action_url


  def hold
    @h = session[:holdings]
    @hd = session[:holdings_detail]
    logger.debug  "getting info for #{params[:id]}" 
    logger.debug  "getting info for #{params[:netid]}" 
    @resp,@document = get_solr_response_for_doc_id(params[:id]) 
    logger.debug  "document info : #{@document}" 
    logger.debug  @document.to_s 
    logger.debug  @document.inspect 
    logger.debug  @document[:title_display]
    logger.debug  "holding info : #{@h}" 
    logger.debug  @h.to_s 
    logger.debug  @h.inspect 
    logger.debug  "holding detail info : #{@hd}" 
    logger.debug  @hd.to_s 
    logger.debug  @hd.inspect 
    @ti =  @document[:title_display]
    @netid =  params[:netid]
    @id =  params[:id]
    if (!@hd.nil?) 
    logger.debug   "details: #{@hd.inspect}"
    # the details offers an array of records, one element for each holding.
    @hd['records'].each do | hol |
      logger.debug  "holding id = #{hol['holding_id']}";
      logger.debug  "item status = #{hol['item_status'].inspect}";
      idl =   hol['item_status']['itemdata'];
      if (!idl.nil?) 
        idl.each do | id |
          logger.debug  "item = #{id['itemid']} #{id['location']} #{id['callNumber']} #{id['copy']} #{id['enumeration']}";
        end
      end
    end
    end # 1==0
  end

  def recall
  @h = session[:holdings]
  logger.debug  "getting info for #{params[:id]}" 
  logger.debug  "getting info for #{params[:netid]}" 
  @resp,@document = get_solr_response_for_doc_id(params[:id]) 
  logger.debug  "document info : #{@document}" 
  logger.debug  @document.to_s 
  logger.debug  @document.inspect 
  logger.debug  @document[:title_display]
  @ti =  @document[:title_display]
  @netid =  params[:netid]
  @id =  params[:id]
  logger.debug   "details: #{@hd.inspect}"
  # the details offers an array of records, one element for each holding.
  if (!@hd.nil?) 
    @hd['records'].each do | hol |
      logger.debug  "holding id = #{hol['holding_id']}";
      logger.debug  "item status = #{hol['item_status'].inspect}";
    end
   end
  end

  def callslip
  @h = session[:holdings]
  logger.debug  "getting info for #{params[:id]}" 
  logger.debug  "getting info for #{params[:netid]}" 
  @resp,@document = get_solr_response_for_doc_id(params[:id]) 
  logger.debug  "info : #{@document}" 
  logger.debug  @document.to_s 
  logger.debug  @document.inspect 
  logger.debug  @document[:title_display]
  @ti =  @document[:title_display]
  @netid =  params[:netid]
  @id =  params[:id]
  logger.debug   "details: #{@hd.inspect}"
  # the details offers an array of records, one element for each holding.
  if (!@hd.nil?) 
    @hd['records'].each do | hol |
      logger.debug  "holding id = #{hol['holding_id']}";
      logger.debug  "item status = #{hol['item_status'].inspect}";
    end
  end
  end

  def l2l
    @h = session[:holdings]
    logger.debug  "getting info for #{params[:id]}" 
    @netid = request.env['HTTP_REMOTE_USER']
    logger.debug  "getting info for #{@netid}" 
    @resp,@document = get_solr_response_for_doc_id(params[:id]) 
    logger.debug  "info : #{@document}" 
    logger.debug  @document.to_s 
    logger.debug  @document.inspect 
    logger.debug  @document[:title_display]
    @ti =  @document[:title_display]
    @id =  params[:id]
    logger.debug   "details: #{@hd.inspect}"
    # the details offers an array of records, one element for each holding.
    if (!@hd.nil?) 
      @hd['records'].each do | hol |
        logger.debug  "holding id = #{hol['holding_id']}";
        logger.debug  "item status = #{hol['item_status'].inspect}";
      end
    end
  end

  def bd
  end

  def ill
  end

  def purchase
  end

  def ask
  end

  def make_request
    @voyager_request_handler_url = Rails.configuration.voyager_request_handler_host
    if @voyager_request_handler_url.blank?
      @voyager_request_handler_url = request.env['HTTP_HOST']
    end
    if !@voyager_request_handler_url.starts_with?('http')
      @voyager_request_handler_url = "http://#{@voyager_request_handler_url}"
    end
    if !Rails.configuration.voyager_request_handler_port.blank?
      @voyager_request_handler_url = @voyager_request_handler_url + ":" + Rails.configuration.voyager_request_handler_port.to_s
    end

    @bid = params[:bid]
    @holding_id = params[:holding_id]
    @library_id = params[:library_id]
    @netid = request.env['HTTP_REMOTE_USER']
    #logger.debug params.inspect

    @voyager_request_handler_url = "#{@voyager_request_handler_url}/holdings/callslip/#{@netid}/#{@bid}/#{@library_id}/#{@holding_id}"
    #logger.debug "posting request to: #{@voyager_request_handler_url}"

    @voyager_response = JSON.parse(HTTPClient.get_content @voyager_request_handler_url)
    #logger.debug @voyager_response

    #render "request/make_request", :layout => false
    render :json => @voyager_response, :layout => false
  end

end
