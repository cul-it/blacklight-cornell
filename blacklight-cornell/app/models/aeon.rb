class Aeon
  
  AEON = 'aeon'
  ASK_LIBRARIAN = 'ask'

  AEON_SITES  = [
    'rmc' ,
    'rmc,anx',
    'rmc,icer',
    'rmc,hsci',
    'was,rare',
    'was,ranx',
    'ech,rare',
    'ech,ranx',
    'sasa,rare',
    'sasa,ranx',
    'hote,rare' 
  ]

  AEON_CODES  = [
    '87' ,
    '203',
    '121',
    '48',
    '143',
    '234',
    '17', 
    '233',
    '126', 
    '232',
    '45' 
  ]
  
  attr_accessor :bibid#, :show_non_rare

  def self.eligible?(lib)
    return AEON_SITES.include?(lib) 
  end 

  def self.eligible_id?(lib)
    return AEON_CODES.include?(lib) 
  end
  
  def request_aeon document, params
    bibid = params[:bibid]
    self.bibid = bibid
    holdings_param = {
      :bibid => bibid
    }
    yholdings = get_holdings holdings_param
    holdings_chf = (yholdings)[bibid]
    holdings = (yholdings) [bibid][:condensed_holdings_full]
    holdings_parsed = {}
    # show_non_rare is not currently used as we don't show any non-rare items
    # on aeon form but if needed, here it is
    # show_non_rare = false;
    # holdings.each do |holding|
      # if (!Aeon.eligible?(holding[:location_code]))
        # show_non_rare = true
      # end
      # holding[:holding_id].each do |holding_id|
        # holdings_parsed[holding_id] = holding
      # end
    # end
    h = holdings
    holdings_param[:type] = 'retrieve_detail_raw'
    raw = get_holdings holdings_param
    holdings_detail = raw[bibid][:records]
    item_types = get_item_types holdings_detail, bibid

    request_options = []
    holdings_detail.each do |holding|
      holding_id = holding[:holding_id]

      holding_type = holding[:item_status][:itemdata]
      if holding_type.count == 0
        next
      end
      holding_status = holding_type[0][:itemStatus]

      holdings_condensed_full_item = holdings_parsed[holding_id]
      item_status = get_item_status holding_status
      request_options.push( _handle_aeon bibid, holding )
    end
    if (!item_types.include?('aeon'))
      # don't know any good way to get at engine's named route...
      # redirect_to Rails.application.routes.url_helpers.blacklight_cornell_request.magic_request_path(bibid)
      # return
    end
    request_options.push( _handle_ask_librarian )
    return request_options, AEON, holdings_chf
  end
  
  def _handle_aeon bibid, holding
    itemdata = holding[:item_status][:itemdata]
    iids = []
    if (!itemdata.nil?)
      itemdata.each do | iid |
        if (! iid[:itemStatus].match('Not Charged') )
          iids.push iid
        end
      end
    end
    return { :service => AEON, :iid => iids }.with_indifferent_access
  end
  
  def _handle_ask_librarian
    return { :service => ASK_LIBRARIAN, :iid => [], :estimate => 9999 }.with_indifferent_access
  end
  
  def get_item_types holdings_detail, bibid
    types = []
    holdings_detail.each do |holding|
      if holding['bibid'] == bibid
        itemdata = holding[:item_status][:itemdata]
        ## request logic is separated into request engine
        ## to show them here, we need to replicate that logic
        ## do we need to show non rare items?
        itemdata.each do |data|
          if (Aeon.eligible_id?(data[:location_id]))
            # sk274_log "Got aeon loan"
            types.push 'aeon'
          end
        end
      end
    end
    return types
  end
  
  def get_item_status item_status
    if item_status.include? 'Not Charged'
      return 'Not Charged'
    elsif item_status =~ /^Charged/
      return 'Charged'
    elsif item_status =~ /Renewed/
      return 'Charged'
    elsif item_status.include? 'Requested'
      return 'Requested'
    elsif item_status.include? 'Missing'
      return 'Missing'
    elsif item_status.include? 'Lost'
      return 'Lost'
    elsif item_status =~ /In transit to(.*)\./
      return 'Charged'
    elsif item_status =~ /In transit/
      return 'Not Charged'
    elsif item_status =~ /On hold/
      return 'Charged'
    else
      return item_status
    end
  end
  
  ##################### Manipulate holdings data #####################

  # Set holdings data from the Voyager service configured in the
  # environments file.
  # holdings_param = { :bibid => <bibid>, :type => retrieve|retrieve_detail_raw}
  def get_holdings params

    return nil unless params[:bibid]
    
    if params[:type].blank?
      params[:type] = 'retrieve'
    end

    response = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/#{params[:type]}/#{params[:bibid]}"))

    # return nil if there is no meaningful response (e.g., invalid bibid)
    return nil if response[self.bibid.to_s].nil?
    
    return response.with_indifferent_access

  end

end
