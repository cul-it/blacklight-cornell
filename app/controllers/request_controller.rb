
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
    @iis = {}
    #@h = session[:holdings]
    #@hd = session[:holdings_details]
    @hd = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_raw/#{params[:id]}"))[params[:id]]
    @h = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @netid = request.env['HTTP_REMOTE_USER']
    logger.debug  "HOLD getting info for #{@netid}" 
    @resp,@document = get_solr_response_for_doc_id(params[:id]) 
    logger.debug  @document[:title_display]
    logger.debug  "HOLD getting info for #{params[:id]}" 
    @ti =  @document[:title_display]
    @au =  @document[:author_display]
    @id =  params[:id]
    logger.debug   "HOLD details: #{@hd.inspect}"
    # the details offers an array of records, one element for each holding.
    if (!@hd.nil?)
      logger.debug  "HOLD holdings = #{@hd}";
      @hd['records'].each do | hol |
        logger.debug  "HOLDholding id = #{hol['holding_id']}";
        logger.debug  "HOLD  item status = #{hol['item_status'].inspect}";
        logger.debug  "HOLD  item status data = #{hol['item_status']['itemdata'].inspect}";
        itemdata = hol["item_status"]["itemdata"];
        logger.debug  "HOLD  hol = #{hol.inspect}";
        logger.debug  "HOLD  item data = #{itemdata.inspect}";
        if (!itemdata.nil?)
          itemdata.each do | iid |
            logger.debug  "item data = #{iid['itemid']}";
            logger.debug  "item caln = #{iid['callNumber']}";
            @iis[iid['itemid']] = iid['location']+' '+iid['callNumber']+' '+iid['copy']+' '+iid['enumeration'];
          end
        end
      end
    end
  end

  def recall
    @iis = {}
    #@h = session[:holdings]
    #@hd = session[:holdings_details]
    @hd = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_raw/#{params[:id]}"))[params[:id]]
    @h = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @netid = request.env['HTTP_REMOTE_USER']
    logger.debug  "RECALL getting info for #{@netid}" 
    @resp,@document = get_solr_response_for_doc_id(params[:id]) 
    logger.debug  @document[:title_display]
    logger.debug  "RECALL getting info for #{params[:id]}" 
    @ti =  @document[:title_display]
    @au =  @document[:author_display]
    @id =  params[:id]
    logger.debug   "RECALL details: #{@hd.inspect}"
    # the details offers an array of records, one element for each holding.
    if (!@hd.nil?)
      logger.debug  "RECALL holdings = #{@hd}";
      @hd['records'].each do | hol |
        logger.debug  "RECALL holding id = #{hol['holding_id']}";
        logger.debug  "RECALL item status = #{hol['item_status'].inspect}";
        logger.debug  "RECALL item status data = #{hol['item_status']['itemdata'].inspect}";
        itemdata = hol["item_status"]["itemdata"];
        logger.debug  "RECALL hol = #{hol.inspect}";
        logger.debug  "RECALL item data = #{itemdata.inspect}";
        if (!itemdata.nil?)
          itemdata.each do | iid |
            logger.debug  "item data = #{iid['itemid']}";
            logger.debug  "item caln = #{iid['callNumber']}";
            @iis[iid['itemid']] = iid['location']+' '+iid['callNumber']+' '+iid['copy']+' '+iid['enumeration'];
          end
        end
      end
    end
  end

  def xhold
    @h = session[:holdings]
    @hd = session[:holdings_detail]
    @netid = request.env['HTTP_REMOTE_USER']
    logger.debug  "getting info for #{params[:id]}" 
    logger.debug  "getting info for #{@netid}" 
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
    @au =  @document[:author_display]
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

  def xrecall
  @h = session[:holdings]
  @netid = request.env['HTTP_REMOTE_USER']
  logger.debug  "getting info for #{params[:id]}" 
  logger.debug  "getting info for #{@netid}" 
  @resp,@document = get_solr_response_for_doc_id(params[:id]) 
  logger.debug  "document info : #{@document}" 
  logger.debug  @document.to_s 
  logger.debug  @document.inspect 
  logger.debug  @document[:title_display]
  @ti =  @document[:title_display]
  @au =  @document[:author_display]
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
  @au =  @document[:author_display]
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
    @iis = {}
    #@h = session[:holdings]
    #@hd = session[:holdings_details]
    @hd = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_raw/#{params[:id]}"))[params[:id]]
    @h = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @netid = request.env['HTTP_REMOTE_USER']
    logger.debug  "L2L getting info for #{@netid}" 
    @resp,@document = get_solr_response_for_doc_id(params[:id]) 
    logger.debug  @document[:title_display]
    logger.debug  "L2L getting info for #{params[:id]}" 
    @ti =  @document[:title_display]
    @au =  @document[:author_display]
    @id =  params[:id]
    logger.debug   "L2L details: #{@hd.inspect}"
    # the details offers an array of records, one element for each holding.
    if (!@hd.nil?)
      logger.debug  "L2L holdings = #{@hd}";
      @hd['records'].each do | hol |
        logger.debug  "L2L holding id = #{hol['holding_id']}";
        logger.debug  "L2L item status = #{hol['item_status'].inspect}";
        logger.debug  "L2L item status data = #{hol['item_status']['itemdata'].inspect}";
        itemdata = hol["item_status"]["itemdata"];
        logger.debug  "L2L hol = #{hol.inspect}";
        logger.debug  "L2L item data = #{itemdata.inspect}";
        if (!itemdata.nil?)
          itemdata.each do | iid |
            logger.debug  "item data = #{iid['itemid']}";
            logger.debug  "item caln = #{iid['callNumber']}";
            @iis[iid['itemid']] = iid['location']+' '+iid['callNumber']+' '+iid['copy']+' '+iid['enumeration'];
          end
        end
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
    voyager_request_handler_url = Rails.configuration.voyager_request_handler_host
    if voyager_request_handler_url.blank?
      voyager_request_handler_url = request.env['HTTP_HOST']
    end
    if !voyager_request_handler_url.starts_with?('http')
      voyager_request_handler_url = "http://#{voyager_request_handler_url}"
    end
    if !Rails.configuration.voyager_request_handler_port.blank?
      voyager_request_handler_url = voyager_request_handler_url + ":" + Rails.configuration.voyager_request_handler_port.to_s
    end

    bid = params[:bid]
    netid = request.env['HTTP_REMOTE_USER']
    library_id = params[:library_id]
    request_action = params[:request_action]
    reqnna = params[:reqnna]
    reqcomments = params[:reqcomments]
    #holding id is actually the ITEM ID.
    holding_id = params[:holding_id]
    add_item_id = ''
    if (holding_id) 
       add_item_id = "/#{holding_id}"
    end
    if request_action == 'callslip'
      voyager_request_handler_url = "#{voyager_request_handler_url}/holdings/#{request_action}/#{netid}/#{bid}/#{library_id}#{add_item_id}"
    elsif request_action == 'bd'
      # fill in borrow direct query
    elsif request_action == 'hold'
        voyager_request_handler_url = "#{voyager_request_handler_url}/holdings/#{request_action}/#{netid}/#{bid}/#{library_id}#{add_item_id}"
    elsif request_action == 'ill'
      # fill in ill request
    elsif request_action == 'purchase'
      # fill in purchase request
    elsif request_action == 'recall'
      voyager_request_handler_url = "#{voyager_request_handler_url}/holdings/#{request_action}/#{netid}/#{bid}/#{library_id}#{add_item_id}"
    else
    end

    logger.debug "posting request to: #{voyager_request_handler_url}"
    body = {"reqnna" => reqnna,"reqcomments"=>reqcomments}
    res = HTTPClient.post(voyager_request_handler_url,body)
    #voyager_response = JSON.parse(HTTPClient.get_content voyager_request_handler_url)
    voyager_response = JSON.parse(res.content)
    logger.debug voyager_response

    #render "request/make_request", :layout => false
    render :json => voyager_response, :layout => false
  end

end
