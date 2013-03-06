
class RequestController < ApplicationController
  include Blacklight::Catalog
  include  Blacklight::Solr
  include Blacklight::SolrHelper

  L2L = 'l2l'
  BD = 'bd'
  HOLD = 'hold'
  RECALL = 'recall'
  PURCHASE = 'purchase' # Note: this is a *purchase request*, which is different from a patron-driven acquisition
  ILL = 'ill'
  ASK_CIRCULATION = 'circ'
  ASK_LIBRARIAN = 'ask'
  ## day after 17, reserve
  IRREGULAR_LOAN_TYPE = {
    :DAY => {
      '1'  => 1,
      '5'  => 1,
      '6'  => 1,
      '7'  => 1,
      '8'  => 1,
      '9'  => 1,
      '10' => 1,
      '11' => 1,
      '13' => 1,
      '14' => 1,
      '15' => 1,
      '17' => 1,
      '18' => 1,
      '19' => 1,
      '20' => 1,
      '21' => 1,
      '23' => 1,
      '24' => 1,
      '24' => 1,
      '25' => 1,
      '28' => 1,
      '33' => 1
      },
    :MINUTE => {
      '12' => 1,
      '16' => 1,
      '22' => 1,
      '26' => 1,
      '27' => 1,
      '29' => 1,
      '30' => 1,
      '31' => 1,
      '32' => 1,
      '34' => 1,
      '35' => 1,
      '36' => 1,
      '37' => 1
    },
    # day loan items with a loan period of 1-2 days cannot use L2L
    :NO_L2L => {
      '10' => 1,
      '17' => 1,
      '23' => 1,
      '24' => 1
    }
  }
  LIBRARY_ANNEX = 'Library Annex'

# Blacklight uses #search_action_url to figure out the right URL for
#   # the global search box
  def search_action_url
         catalog_index_url
  end
  helper_method :search_action_url

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

  # Authenticate and bind to Cornell's Active Directory LDAP service
  # Returns an ldap object that can be used for searches (or nil on failure)
  def bind_ldap

    # Login credentials (provided by Desktop Services)
    holding_id_dn = 'CN=LIB-BlacklightDev-hid,OU=DS support areas,OU=HoldingIDs,OU=IDs,OU=LIBRARY,OU=DelegatedObjects,DC=cornell,DC=edu'
    holding_pw = 'callufr@x13'

    # Set up LDAP connection
    ldap = Net::LDAP.new
    ldap.host = 'query.ad.cornell.edu'
    ldap.port = 389
    ldap.auth holding_id_dn, holding_pw

    if ldap.bind
      return ldap
    else
      return nil
    end
  end

  # Return our requests-specific patron type by looking at
  # the LDAP entry's reference groups.
  # Our basic assumption: a person is student/faculty/staff if he/she belongs to
  #  one of the following reference groups:
  #    rg.cuniv.employee, rg.cuniv.student
  # Reference Groups reference page is http://www.it.cornell.edu/services/group/about/reference.cfm
  def get_patron_type netid

    unless netid.nil?
      patron_dn = get_ldap_dn netid
      return nil if patron_dn.nil?

      ldap = bind_ldap
      return unless ldap

      # Do our search
      search_params = { :base =>   patron_dn, 
                        :scope =>  Net::LDAP::SearchScope_BaseObject,
                        :attrs =>  ['tokenGroups'] }
      ldap.search(search_params) do |entry|

        # This is a brute-force approach because I can't make sense of LDAP
        # Just match all the attributes of the form 'CN=rg.whatever'
        reference_groups = entry.to_ldif.scan(/CN=(rg.*?),/).flatten
        if reference_groups.include? "rg.cuniv.employee" or reference_groups.include? "rg.cuniv.student"
          return "cornell"
        else
          return "guest"
        end
      end

    end
  end

  # Return a user's distinguished name (dn) from an LDAP lookup
  # TODO: This function seems pontentially reusable. Figure out where to put it so that
  # more controllers (and models?) can access it
  # This is based heavily on sample Perl code from ss488, CIT, at 
  #    https://confluence.cornell.edu/download/attachments/118767666/tokengroups.pl
  def get_ldap_dn netid

    # Login credentials (provided by Desktop Services)
    holding_id_dn = 'CN=LIB-BlacklightDev-hid,OU=DS support areas,OU=HoldingIDs,OU=IDs,OU=LIBRARY,OU=DelegatedObjects,DC=cornell,DC=edu'
    holding_pw = 'callufr@x13'

    ldap = bind_ldap
    return unless ldap

    # Do our search
    search_params = { :base => 'DC=cornell,DC=edu', 
                      :filter => Net::LDAP::Filter.eq('sAMAccountName', netid), 
                      :attrs => ['distinguishedName'] }
    ldap.search(search_params) do |entry|
      return entry.dn
    end
  end

  def get_item_type holdings_detail, bibid
    ## there are three types of loans
    ## regular
    ## day
    ## minute
    ## 'regular'
    holdings_detail.each do |holding|
      if holding['bibid'] == bibid
        itemdata = holding['item_status']['itemdata']
        itemdata.each do |data|
          if IRREGULAR_LOAN_TYPE[:DAY][data['typeCode']] == 1
            logger.debug "Got day loan"
            return 'day'
          elsif IRREGULAR_LOAN_TYPE[:MINUTE][data['typeCode']] == 1
            logger.debug "Got minute loan"
            return 'minute'
          end
        end
      end
    end
    logger.debug "Got regular loan"
    return 'regular'
  end

  def request_item target=''
    netid = request.env['REMOTE_USER']
    bibid = params[:id]
    isbn  = params[:isbn]
    title = params[:title]
    holdings_param = {
      :bibid => bibid
    }

    ## sk274
    ## It would be the best if we could pull consolidated data out of voyager
    ##   but as it stands now, condensed_holdings_full gives us availability
    ##   and retrieve_detail_raw gives us item type.
    ## Make holdings consolidated view key off of holdings id so we can easily cross reference
    holdings = ( get_holdings holdings_param )[bibid]['condensed_holdings_full']
    #logger.info holdings.inspect
    holdings_parsed = {}
    holdings.each do |holding|
      ## condensed_holdings_full groups holding_id's from same location together
      ##   but retrieve_detail_raw lists each holding_id separately
      holding['holding_id'].each do |holding_id|
        holdings_parsed[holding_id] = holding
      end
    end
    holdings_param[:type] = 'retrieve_detail_raw'
    raw = get_holdings holdings_param
    holdings_detail = raw[bibid]['records']
    # logger.info "\n\n"
    logger.info holdings_detail.inspect
    item_type = get_item_type holdings_detail, bibid
    # logger.info "item type: #{item_type}"

    netid = request.env['REMOTE_USER']
    patron_type = get_patron_type netid
    @request_solution = ''
    request_options = []

    # logger.debug "netid: #{netid}"
    # logger.debug holdings.inspect

    holdings_detail.each do |holding|
      holding_id = holding['holding_id']
      holding_type = holding['item_status']['itemdata'][0]['typeCode']
      holdings_condensed_full_item = holdings_parsed[holding_id]
      logger.debug "status: #{holdings_condensed_full_item['status']}"
      ## is requested treated same as charged?
      item_status = get_item_status holding['item_status']['itemdata'][0]['itemStatus']
      if holdings_condensed_full_item['location_name'] == '*Networked Resource'
        logger.debug "branch 0"
        next
      elsif patron_type == 'cornell' && item_type == 'regular' && item_status == 'Charged'
        ## BD RECALL ILL HOLD
        logger.debug "branch 1a"
        _handle_bd bibid, holding
        request_options.push( _handle_recall bibid, holding )
        request_options.push( _handle_ill bibid, holding )
        request_options.push( _handle_hold bibid, holding )
      elsif patron_type == 'cornell' && item_type == 'regular' && item_status == 'Requested'
        ## BD ILL HOLD RECALL
        logger.debug "branch 1b"
        _handle_bd bibid, holding
        request_options.push( _handle_recall bibid, holding )
        request_options.push( _handle_ill bibid, holding )
        request_options.push( _handle_hold bibid, holding )
      elsif patron_type == 'cornell' && item_type == 'regular' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 2"
        request_options.push( _handle_l2l bibid, holding )
      elsif patron_type == 'cornell' && item_type == 'regular' && ( item_status == 'Missing' || item_status == 'Lost' )
        ## BD PURCHASE ILL
        logger.debug "branch 3"
        _handle_bd bibid, holding
        request_options.push( _handle_purchase bibid, holding )
        request_options.push( _handle_ill bibid, holding )
      elsif patron_type == 'guest' && item_type == 'regular' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## HOLD
        logger.debug "branch 4"
        request_options.push( _handle_hold bibid, holding )
      elsif patron_type == 'guest' && item_type == 'regular' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 5"
        request_options.push( _handle_l2l bibid, holding )
      elsif patron_type == 'cornell' && item_type == 'minute' && ( item_status == 'Charged' || item_status == 'Requested' )
        ##  BD ASK_CIRCULATION
        logger.debug "branch 6"
        request_options.push( _handle_ask_circulation bibid, holding )
        _handle_bd bibid, holding
      elsif patron_type == 'cornell' && item_type == 'day' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## BD ILL HOLD
        logger.debug "branch 7"
        _handle_bd bibid, holding
        request_options.push( _handle_ill bibid, holding )
        request_options.push( _handle_hold bibid, holding )
      elsif patron_type == 'guest' && ( item_status == 'Missing' || item_status == 'Lost' )
        ## ASK_LIBRARIAN
        logger.debug "branch 8"
      elsif patron_type == 'guest' && item_type == 'day' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## HOLD
        logger.debug "branch 9"
        request_options.push( _handle_hold bibid, holding )
      elsif patron_type == 'guest' && item_type == 'minute' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## ASK_LIBRARIAN ASK_CIRCULATION
        logger.debug "branch 10"
        request_options.push( _handle_ask_circulation bibid, holding )
      # Removed branch 11 - duplicate of branch 2
      elsif patron_type == 'cornell' && item_type == 'day' && item_status == 'Not Charged'
        ## LTL 
        logger.debug "branch 12"
        request_options.push( _handle_l2l bibid, holding ) if IRREGULAR_LOAN_TYPE[:NO_L2L][holding_type] != 1
        # TODO: revisit whether to offer BD once we have an API from relais
        # _handle_bd bibid, holding, request_options, params
      elsif patron_type == 'cornell' && item_type == 'minute' && item_status == 'Not Charged'
        ## BD ASK_CIRCULATION
        logger.debug "branch 13"
        request_options.push( _handle_ask_circulation bibid, holding )
        _handle_bd bibid, holding
      elsif patron_type == 'guest' && item_type == 'regular' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 14"
        request_options.push( _handle_l2l bibid, holding )
      elsif patron_type == 'guest' && item_type == 'day' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 15" 
        request_options.push( _handle_l2l bibid, holding ) if IRREGULAR_LOAN_TYPE[:NO_L2L][holding_type] != 1
      elsif patron_type == 'guest' && item_type == 'minute' && item_status == 'Not Charged'
        ## ASK_LIBRARIAN ASK_CIRCULATION
        request_options.push( _handle_ask_circulation bibid, holding )
        logger.debug "branch 16"
      else
        ## ASK_LIBRARIAN
        logger.debug "branch 17 - #{patron_type}, #{item_type}, #{holding['item_status']['itemdata'][0]['itemStatus']}"
      end
       request_options.push( _handle_ask_librarian bibid, holding )
    end

    request_options.each do |a|
      logger.info "#{a[:service]}: #{a[:estimate]}"
    end

    request_options = sort_request_options request_options

    request_options.each do |a|
      logger.info "#{a[:service]}: #{a[:estimate]}"
    end

    ## sk274 - online resource first?
    if !target.blank?
      #eval "#{target} request_options"
      _display request_options, target
    elsif request_options.present?
      best_option = request_options[0]
      #eval "_#{best_option[:service]} request_options"
      _display request_options, best_option[:service]
    else
      _display request_options, 'ask'
    end

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
    else
      return item_status
    end
  end

  def get_l2l_delivery_time itemdata
    if itemdata['location'] == LIBRARY_ANNEX
      return 1
    else
      return 2
    end
  end

  def get_bd_delivery_time bd_list
    return 6
  end

  def get_hold_delivery_time hold_list
    return 180
  end

  def get_recall_delivery_time recall_list
    return 30
  end

  def get_ill_delivery_time ill_list
    return 14
  end

  def get_purchase_delivery_time purchase_list
    return 10
  end

  def sort_request_options request_options
    return request_options.sort_by { |option| option[:estimate] }
  end

  def _display request_options, service
    @resp,@document = get_solr_response_for_doc_id(params[:id])
    @ti = @document[:title_display]
    @au = @document[:author_display]
    @isbn = @document[:isbn_display]
    @ill_link = 'https://cornell.hosts.atlas-sys.com/illiad/illiad.dll?Action=10&Form=30&url_ver=Z39.88-2004&rfr_id=info%3Asid%2Flibrary.cornell.edu'
    if @isbn.present?
      isbns = @isbn.join(',')
      @ill_link = @ill_link + "&rft.isbn=#{isbns}"
      @ill_link = @ill_link + "&rft_id=urn%3AISBN%3A#{isbns}"
    end
    if !@ti.blank?
      @ill_link = @ill_link + "&rft.btitle=#{@ti}"
    end
    if !@document[:author_display].blank?
      @ill_link = @ill_link + "&rft.aulast=#{@document[:author_display]}"
    end
    if @document[:pub_info_display].present?
      pub_info_display = @document[:pub_info_display][0]
      @ill_link = @ill_link + "&rft.place=#{pub_info_display}"
      @ill_link = @ill_link + "&rft.pub=#{pub_info_display}"
      @ill_link = @ill_link + "&rft.date=#{pub_info_display}"
    end
    if !@document[:format].blank?
      @ill_link = @ill_link + "&rft.genre=#{@document[:format]}"
    end
    if @document[:lc_callnum_display].present?
      @ill_link = @ill_link + "&rft.identifier=#{@document[:lc_callnum_display][0]}"
    end
    @id = params[:id]
    @iis = {}
    @alternate_request_options = []
    seen = {}
    request_options.each do |item|
      if item[:service] == service
        iids = item[:iid]
        iids.each do |iid|
          @iis[iid['itemid']] = iid['location']+' '+iid['callNumber']+' '+iid['copy']+' '+iid['enumeration']
        end
      else
        ## get the lowest estimate from this item
        estimate = 9999
        iids = item[:iid]
        iids.each do |iid|
          if estimate > iid[:estimate]
            estimate = iid[:estimate]
          end
        end
        ## if we didn't see this request option before or this estimate is lower than previous one,
        ## update seen hash with lowest estimate for this service
        if ! seen[item[:service]] || seen[item[:service]] > estimate
          seen[item[:service]] = estimate
        end
      end
    end

    seen.each do |service, estimate|
      @alternate_request_options.push({ :option => service, :estimate => estimate})
    end
    @alternate_request_options = sort_request_options @alternate_request_options

    render service
  end

  def l2l
    return request_item L2L
  end

  def hold
    return request_item HOLD
  end

  def recall
    return request_item RECALL
  end

  def bd
    return request_item BD
  end

  def ill
    return request_item ILL
  end

  def purchase
    return request_item PURCHASE
  end

  def ask
    return request_item ASK_LIBRARIAN
  end

  def borrowDirect_available? params
    borrow_direct_webservices_url = Rails.configuration.borrow_direct_webservices_host
    if borrow_direct_webservices_url.blank?
      borrow_direct_webservices_url = request.env['HTTP_HOST']
      #borrow_direct_webservices_url = "http://sk274-dev.library.cornell.edu"
    end
    if !borrow_direct_webservices_url.starts_with?('http')
      borrow_direct_webservices_url = "http://#{borrow_direct_webservices_url}"
    end
    if !Rails.configuration.borrow_direct_webservices_port.blank?
      borrow_direct_webservices_url = borrow_direct_webservices_url + ":" + Rails.configuration.borrow_direct_webservices_port.to_s
    end

    if params[:isbn].blank? && params[:title].blank?
      ## no valid params passed
      return false
    end

    # logger.info (params[:isbn]).class
    # logger.info params[:isbn].inspect

    ## initialize pazpar2 session
    request_url = borrow_direct_webservices_url + '/search.pz2?command=init'
    response = HTTPClient.get_content(request_url)
    response_parsed = Hash.from_xml(response)
    session_id = response_parsed['init']['session']
    # logger.info "session id: #{session_id}"

    ## make pazpar2 search
    isbn = params[:isbn].scan(/"([a-zA-Z0-9]+)[ "]/)
    # logger.info isbn.inspect
    if isbn.length == 1
      request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=search&query=isbn%3D#{isbn[0][0]}"
    elsif isbn.length > 0 && params[:title].blank?
      request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=search&query=isbn%3D#{isbn[0][0]}"
    elsif !params[:title].blank?
      request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=search&query=ti%3D#{params[:title]}"
    else
      return false
    end
    response = HTTPClient.get_content(request_url)
    response_parsed = Hash.from_xml(response)
    status = response_parsed['search']['status']
    if status != 'OK'
      ## invalid search
      return false
    end

    ## get pazpar2 recid from show command to get record information
    ## make stat request repeatedly to check if the search process finished
    sleep(0.5)
    i = 0
    progress = '0.00'
    request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=stat"
    while (progress != '1.00' && i < 120)
      response = HTTPClient.get_content(request_url)
      response_parsed = Hash.from_xml(response)
      progress = response_parsed['stat']['progress']
      i = i + 1
      sleep(1)
    end
    # logger.info "finished search request in #{i} seconds"
    ## make show request to get record id
    request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=show&start=0&num=2&sort=title:1"
    response = HTTPClient.get_content(request_url)
    response_parsed = Hash.from_xml(response)
    hits = response_parsed['show']['hit']
    if hits.blank? || hits.class == String
      return false
    elsif hits.class == Hash
      return _determine_availablility? borrow_direct_webservices_url, session_id, hits
    elsif hits.class == Array
      hits.each do |hit|
        return true if _determine_availablility? borrow_direct_webservices_url, session_id, hit
      end
    else
      ## error?
    end

    ## get record for each hit returned until we find first available item or there is no more
    return false
  end

  def _determine_availablility? borrow_direct_webservices_url, session_id, hit
    recid = hit['recid']
    request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=record&id=#{recid}"
    response = HTTPClient.get_content(URI::escape(request_url))
    response_parsed = Hash.from_xml(response)
    availabilities = response_parsed['record']['location']['md_available']
    if availabilities.class == String
      if availabilities.strip == 'Available'
        return true
      end
    elsif availabilities.class == Array
      availabilities.each do |availability|
        if availability.strip == 'Available'
          return true
        end
      end
    else
      ## what is this?
      logger.debug availabilities.inspect
      return false
    end
  end

  def get_holdings holdings_param
    if holdings_param[:type].blank?
      holdings_param[:type] = 'retrieve'
    end
    return JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/#{holdings_param[:type]}/#{holdings_param[:bibid]}"))
  end

  def _handle_l2l bibid, holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    estimate = 9999
    if (!itemdata.nil?)
      itemdata.each do | iid |
        #itemStatus"=>"Not Charged",
        if ( (! iid['location'].match('Non-Circulating')) && (iid['itemStatus'].match('Not Charged')))
          iid[:estimate] = get_l2l_delivery_time iid
          iids.push iid
          if estimate > iid[:estimate]
            estimate = iid[:estimate]
          end
        end
      end
    end
    return { :service => L2L, :iid => iids, :estimate => estimate }
  end

  def _handle_bd bibid, holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    estimate = 9999
    if (!itemdata.nil?)
      itemdata.each do | iid |
        #itemStatus"=>"Not Charged",
        if (! iid['itemStatus'].match('Not Charged') )
          iid[:estimate] = get_bd_delivery_time iid
          iids.push iid
          if estimate > iid[:estimate]
            estimate = iid[:estimate]
          end
        end
      end
    end
    return { :service => BD, :iid => iids, :estimate => estimate }
  end

  def _handle_hold bibid, holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    estimate = 9999
    if (!itemdata.nil?)
      itemdata.each do | iid |
        logger.info itemdata.inspect
        #itemStatus"=>"Not Charged",
        if (! iid['itemStatus'].match('Not Charged') )
          iid[:estimate] = get_hold_delivery_time iid
          iids.push iid
          if estimate > iid[:estimate]
            estimate = iid[:estimate]
          end
        end
      end
    end
    return { :service => HOLD, :iid => iids, :estimate => estimate }
  end

  def _handle_recall bibid, holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    if (!itemdata.nil?)
      itemdata.each do | iid |
        #itemStatus"=>"Not Charged",
        if (! iid['itemStatus'].match('Not Charged') )
          iid[:estimate] = get_recall_delivery_time iid
          iids.push iid
        end
      end
    end
    return { :service => RECALL, :iid => iids, :estimate => get_recall_delivery_time(1) }
  end

  # Note: this is a *purchase request*, which is different from a patron-driven acquisition
  def _handle_purchase bibid, holding
    iids = []
    return { :service => PURCHASE, :iid => iids, :estimate => get_purchase_delivery_time(1) }
  end

  def _handle_ill bibid, holding
    iids = []
    return { :service => ILL, :iid => iids, :estimate => get_ill_delivery_time(1) }
  end

  def _handle_ask_circulation bibid, holding
    iids = []
    return { :service => ASK_CIRCULATION, :iid => iids, :estimate => 9998 }
  end

  def _handle_ask_librarian bibid, holding
    iids = []
    return { :service => ASK_LIBRARIAN, :iid => iids, :estimate => 9999 }
  end

end
