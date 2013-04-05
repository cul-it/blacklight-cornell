
class RequestController < ApplicationController
  include Blacklight::Catalog
  include  Blacklight::Solr
  include Blacklight::SolrHelper

  L2L = 'l2l'
  BD = 'bd'
  HOLD = 'hold'
  RECALL = 'recall'
  PURCHASE = 'purchase' # Note: this is a *purchase request*, which is different from a patron-driven acquisition
  PDA = 'pda'
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
    },
    :NOCIRC => {
      '9'  => 1
    }
  }
  LIBRARY_ANNEX = 'Library Annex'
  HOLD_PADDING_TIME = 3

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

  # Process submitted form data from hold/recall/callslip/purchase request forms and perform the appropriate call
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
    reqnna = params['latest-date']
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
      # Handled below
    elsif request_action == 'recall'
      voyager_request_handler_url = "#{voyager_request_handler_url}/holdings/#{request_action}/#{netid}/#{bid}/#{library_id}#{add_item_id}"
    else
    end

    if request_action == 'purchase'
      # Validate the form submission
      # logger.debug(params)
      if params[:name].blank?
        flash[:error] = I18n.t('blacklight.requests.errors.name.blank')
      elsif params[:reqstatus].blank?
        flash[:error] = I18n.t('blacklight.requests.errors.status.blank')
      elsif params[:reqtitle].blank?
        flash[:error] = I18n.t('blacklight.requests.errors.title.blank')
      elsif params[:email].blank?
        flash[:error] = I18n.t('blacklight.requests.errors.email.blank')
      elsif params[:email].present?
        if params[:email].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
          # Email the form contents to the purchase request staff
          RequestMailer.email_request(netid, params)
          # TODO: check for mail errors, don't assume that things are working!
          flash[:success] = I18n.t('blacklight.requests.success')
        else
          flash[:error] = I18n.t('blacklight.requests.errors.email.invalid')
        end
      end
    else
      # Validate the form submission
      if params[:holding_id].blank?
        flash[:error] = I18n.t('blacklight.requests.errors.holding_id.blank')
      elsif params[:library_id].blank?
        flash[:error] = I18n.t('blacklight.requests.errors.library_id.blank')
      else
        # Send a request to Voyager
        logger.debug "posting request to: #{voyager_request_handler_url}"
        body = {"reqnna" => reqnna,"reqcomments"=>reqcomments}
        res = HTTPClient.post(voyager_request_handler_url,body)
        #voyager_response = JSON.parse(HTTPClient.get_content voyager_request_handler_url)
        voyager_response = JSON.parse(res.content)
        logger.debug voyager_response
        flash[:success] = I18n.t('blacklight.requests.success')
      end
    end

    #render "request/make_request", :layout => false
    # render :json => voyager_response, :layout => false
    render :partial => '/flash_msg', :layout => false
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
          itemType = _get_item_type data
          return itemType unless itemType == 'regular'
        end
      end
    end
    # logger.debug "Got regular loan"
    return 'regular'
  end

  def _get_item_type data
    ## there are three types of loans
    ## regular
    ## day
    ## minute
    ## 'regular'
    if IRREGULAR_LOAN_TYPE[:NOCIRC][data['typeCode']] == 1
      logger.debug 'Got nocirc'
      return 'nocirc'
    elsif IRREGULAR_LOAN_TYPE[:DAY][data['typeCode']] == 1
      logger.debug "Got day loan"
      return 'day'
    elsif IRREGULAR_LOAN_TYPE[:MINUTE][data['typeCode']] == 1
      logger.debug "Got minute loan"
      return 'minute'
    end
    # logger.debug "Got regular loan"
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
    logger.debug holdings_detail.inspect

    item_type = get_item_type holdings_detail, bibid
    # logger.info "item type: #{item_type}"

    netid = request.env['REMOTE_USER']
    patron_type = get_patron_type netid
    @request_solution = ''
    request_options = []

    # logger.debug "netid: #{netid}"
    # logger.debug holdings.inspect

    resp, document = get_solr_response_for_doc_id(params[:id])
    bdParams = { :isbn => document['isbn_display'], :title => URI::escape(document['title_display']) }
    # logger.info bdParams.inspect

    if item_type == 'nocirc'
      if patron_type == 'cornell'
        ## BD, ILL, ASK
        if borrowDirect_available? bdParams
          request_options.push({ :service => BD, :iid => [], :estimate => get_bd_delivery_time })
          if target.blank?
            target = BD
          end
        end
        request_options.push({ :service => ILL, :iid => [], :estimate => get_ill_delivery_time })
        request_options.push( _handle_ask_librarian )
        if target.blank?
          target = ILL
        end
      else
        ## ASK
        request_options.push( _handle_ask_librarian )
        target = ASK
      end
      _display request_options, target, document
      return
    end

    if patron_type == 'cornell' && !document['url_pda_display'].blank?
      logger.debug "pda"
      request_options.push( _handle_pda document['url_pda_display'] )
      if borrowDirect_available? bdParams
        request_options.push({ :service => BD, :iid => [], :estimate => get_bd_delivery_time })
      end
      request_options.push({ :service => ILL, :iid => [], :estimate => get_ill_delivery_time })
      request_options.push( _handle_ask_librarian )
      if target.blank?
        target = PDA
      end
      _display request_options, target, document
      return
    end

    holdings_detail.each do |holding|
      holding_id = holding['holding_id']
      holding_type = holding['item_status']['itemdata']
      if holding_type.count == 0
        request_options.push( _handle_ask_librarian )
        next
      end

      holding_type = holding_type[0]['typeCode']
      holdings_condensed_full_item = holdings_parsed[holding_id]
      # logger.debug "status: #{holdings_condensed_full_item['status']}"
      ## is requested treated same as charged?
      item_status = get_item_status holding['item_status']['itemdata'][0]['itemStatus']

      if holdings_condensed_full_item['location_name'] == '*Networked Resource'
        logger.debug "branch 0"
        next
      elsif patron_type == 'cornell' && item_type == 'regular' && item_status == 'Charged'
        ## BD RECALL ILL HOLD
        logger.debug "branch 1a"
        _handle_bd holding, request_options, bdParams
        request_options.push( _handle_recall holding )
        request_options.push( _handle_ill holding )
        request_options.push( _handle_hold holding )
      elsif patron_type == 'cornell' && item_type == 'regular' && item_status == 'Requested'
        ## BD ILL HOLD RECALL
        logger.debug "branch 1b"
        _handle_bd holding, request_options, bdParams
        request_options.push( _handle_recall holding )
        request_options.push( _handle_ill holding )
        request_options.push( _handle_hold holding )
      elsif patron_type == 'cornell' && item_type == 'regular' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 2"
        request_options.push( _handle_l2l holding )
      elsif patron_type == 'cornell' && item_type == 'regular' && ( item_status == 'Missing' || item_status == 'Lost' )
        ## BD PURCHASE ILL
        logger.debug "branch 3"
        _handle_bd holding, request_options, bdParams
        request_options.push( _handle_purchase holding )
        request_options.push( _handle_ill holding )
      elsif patron_type == 'guest' && item_type == 'regular' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## HOLD
        logger.debug "branch 4"
        request_options.push( _handle_hold holding )
      elsif patron_type == 'guest' && item_type == 'regular' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 5"
        request_options.push( _handle_l2l holding )
      elsif patron_type == 'cornell' && item_type == 'minute' && ( item_status == 'Charged' || item_status == 'Requested' )
        ##  BD ASK_CIRCULATION
        logger.debug "branch 6"
        request_options.push( _handle_ask_circulation holding )
        _handle_bd holding, request_options, bdParams
      elsif patron_type == 'cornell' && item_type == 'day' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## BD ILL HOLD
        logger.debug "branch 7"
        _handle_bd holding, request_options, bdParams
        request_options.push( _handle_ill holding )
        request_options.push( _handle_hold holding )
      elsif patron_type == 'guest' && ( item_status == 'Missing' || item_status == 'Lost' )
        ## ASK_LIBRARIAN
        logger.debug "branch 8"
      elsif patron_type == 'guest' && item_type == 'day' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## HOLD
        logger.debug "branch 9"
        request_options.push( _handle_hold holding )
      elsif patron_type == 'guest' && item_type == 'minute' && ( item_status == 'Charged' || item_status == 'Requested' )
        ## ASK_LIBRARIAN ASK_CIRCULATION
        logger.debug "branch 10"
        request_options.push( _handle_ask_circulation holding )
      # Removed branch 11 - duplicate of branch 2
      elsif patron_type == 'cornell' && item_type == 'day' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 12"
        request_options.push( _handle_l2l holding ) if IRREGULAR_LOAN_TYPE[:NO_L2L][holding_type] != 1
        # TODO: revisit whether to offer BD once we have an API from relais
        # _handle_bd bibid, holding, request_options, params
      elsif patron_type == 'cornell' && item_type == 'minute' && item_status == 'Not Charged'
        ## BD ASK_CIRCULATION
        logger.debug "branch 13"
        request_options.push( _handle_ask_circulation holding )
        _handle_bd holding, request_options, bdParams
      elsif patron_type == 'guest' && item_type == 'regular' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 14"
        request_options.push( _handle_l2l holding )
      elsif patron_type == 'guest' && item_type == 'day' && item_status == 'Not Charged'
        ## LTL
        logger.debug "branch 15"
        request_options.push( _handle_l2l holding ) if IRREGULAR_LOAN_TYPE[:NO_L2L][holding_type] != 1
      elsif patron_type == 'guest' && item_type == 'minute' && item_status == 'Not Charged'
        ## ASK_LIBRARIAN ASK_CIRCULATION
        request_options.push( _handle_ask_circulation holding )
        logger.debug "branch 16"
      end
      logger.debug "branch 18 - default ask librarian"
      request_options.push( _handle_ask_librarian )
    end

    # request_options.each do |a|
    #   logger.info "#{a[:service]}: #{a[:estimate]}"
    # end

    request_options = sort_request_options request_options

    # request_options.each do |a|
    #   logger.info "#{a[:service]}: #{a[:estimate]}"
    # end

    ## sk274 - online resource first?
    if !target.blank?
      #eval "#{target} request_options"
      _display request_options, target, document
    elsif request_options.present?
      best_option = request_options[0]
      #eval "_#{best_option[:service]} request_options"
      _display request_options, best_option[:service], document
    else
      _display request_options, 'ask', document
    end

  end

  ## for now, treat in transit, in transit discharged as not charged
  ## should we add a few days for delivery date?
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

  def get_l2l_delivery_time itemdata
    if itemdata['location'] == LIBRARY_ANNEX
      return 1
    else
      return 2
    end
  end

  def get_bd_delivery_time
    return 6
  end

  def get_hold_delivery_time hold_iid
    ## if it got to this point, it means it is not available and should have Due on xxxx-xx-xx
    dueDate = /.*Due on (\d\d\d\d-\d\d-\d\d)/.match(hold_iid['itemStatus'])
    if ! dueDate.nil?
      estimate = (Date.parse(dueDate[1]) - Date.today).to_i
      if (estimate < 0)
        ## this item is overdue
        ## use default value instead
        estimate = 180
      end
      ## pad for extra days for processing time?
      ## also padding would allow l2l to be always first option
      return estimate.to_i + HOLD_PADDING_TIME
    else
      ## due date not found... use default
      return 180
    end
  end

  def get_recall_delivery_time hold_iid
    return 30
  end

  def get_ill_delivery_time
    return 14
  end

  def get_purchase_delivery_time
    return 10
  end

  def get_pda_delivery_time
    return 5
  end

  def sort_request_options request_options
    return request_options.sort_by { |option| option[:estimate] }
  end

  def _display request_options, service, doc
    # if doc.blank?
    #   @resp,@document = get_solr_response_for_doc_id(params[:id])
    # else
      @document = doc
    # end
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
      @pub_info = pub_info_display
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
          @iis[iid['itemid']] = {
            :location => iid['location'],
            :location_id => iid['location_id'],
            :call_number => iid['callNumber'],
            :copy => iid['copy'],
            :enumeration => iid['enumeration'],
            :url => iid['url'],
            :chron => iid['chron']
          }
        end
      else
        ## get the lowest estimate from this item
        # estimate = 9999
        # iids = item[:iid]
        # iids.each do |iid|
        #   if estimate > iid[:estimate]
        #     estimate = iid[:estimate]
        #   end
        # end

        ## if we didn't see this request option before or this estimate is lower than previous one,
        ## update seen hash with lowest estimate for this service
        if ! seen[item[:service]] || seen[item[:service]] > item[:estimate]
          seen[item[:service]] = item[:estimate]
        end
      end
    end

    seen.each do |service, estimate|
      @alternate_request_options.push({ :option => service, :estimate => estimate})
    end
    @alternate_request_options = sort_request_options @alternate_request_options

    # Pass through BD delivery time
    if service == BD
      @delivery_time = get_bd_delivery_time
    end
    # logger.info @iis.inspect

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

  def pda
    return request_item PDA
  end

  def ask
    return request_item ASK_LIBRARIAN
  end

  def borrowDirect_available? params
    availability = false
    begin
      availability = _borrowDirect_available? params
    rescue => e
      logger.warn "Error checking borrow direct availability: exception #{e.class.name} : #{e.message}"
      availability = false
    end
    return availability
  end

  def _borrowDirect_available? params
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
    isbn = /([a-zA-Z0-9]+)/.match(params[:isbn][0])
    isbn = isbn[1]
    # isbn = params[:isbn][0].scan(/"([a-zA-Z0-9]+)[ "]/)
    # logger.info "isbn:"
    # logger.info isbn.inspect
    if isbn.blank? && !params[:title].blank?
      request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=search&query=ti%3D#{params[:title]}"
    elsif !isbn.blank?
      request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=search&query=isbn%3D#{isbn}"
    else
      return false
    end
    # logger.info "request url: #{request_url}"
    response = HTTPClient.get_content(request_url)
    response_parsed = Hash.from_xml(response)
    status = response_parsed['search']['status']
    if status != 'OK'
      ## invalid search
      logger.info "Invalid search: #{status}"
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
      # logger.debug availabilities.inspect
      return false
    end
  end

  def get_holdings holdings_param
    if holdings_param[:type].blank?
      holdings_param[:type] = 'retrieve'
    end
    return JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/#{holdings_param[:type]}/#{holdings_param[:bibid]}"))
  end

  def _handle_l2l holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    estimate = 9999
    if (!itemdata.nil?)
      itemdata.each do | iid_ref |
        iid = deep_copy(iid_ref)
        logger.info iid.inspect
        logger.info "\n"
        #itemStatus"=>"Not Charged",
        itemType = _get_item_type iid
        item_status = get_item_status iid['itemStatus']
        if ( (! iid['location'].include?('Non-Circulating')) && (item_status.include?('Not Charged')) && itemType != 'minute' && IRREGULAR_LOAN_TYPE[:NO_L2L][iid['typeCode']] != 1)
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

  def _handle_bd holding, request_options, bdParams
    if borrowDirect_available? bdParams
      itemdata = holding["item_status"]["itemdata"]
      iids = []
      estimate = 9999
      if (!itemdata.nil?)
        itemdata.each do | iid_ref |
          iid = deep_copy(iid_ref)
          #itemStatus"=>"Not Charged",
          item_status = get_item_status iid['itemStatus']
          if (! item_status.match('Not Charged') )
            iid[:estimate] = get_bd_delivery_time
            iids.push iid
            if estimate > iid[:estimate]
              estimate = iid[:estimate]
            end
          end
        end
        bdEntry = { :service => BD, :iid => iids, :estimate => estimate }
        request_options.push bdEntry
      end
    end
  end

  def _handle_hold holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    estimate = 9999
    if (!itemdata.nil?)
      itemdata.each do | iid_ref |
        iid = deep_copy(iid_ref)
        # logger.info itemdata.inspect
        #itemStatus"=>"Not Charged",
        item_status = get_item_status iid['itemStatus']
        if (! item_status.match('Not Charged') )
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

  def _handle_recall holding
    itemdata = holding["item_status"]["itemdata"]
    iids = []
    estimate = 9999
    if (!itemdata.nil?)
      itemdata.each do | iid_ref |
        iid = deep_copy(iid_ref)
        #itemStatus"=>"Not Charged",
        item_status = get_item_status iid['itemStatus']
        if (! item_status.match('Not Charged') )
          iid[:estimate] = get_recall_delivery_time iid
          iids.push iid
          if estimate > iid[:estimate]
            estimate = iid[:estimate]
          end
        end
      end
    end
    return { :service => RECALL, :iid => iids, :estimate => estimate }
  end

  # Note: this is a *purchase request*, which is different from a patron-driven acquisition
  def _handle_purchase holding
    iids = []
    return { :service => PURCHASE, :iid => iids, :estimate => get_purchase_delivery_time }
  end

  def _handle_pda pda_url
    pda_url = pda_url[0]
    pda_url, note = pda_url.split('|')
    iids = [ { 'itemid' => 'pda', 'url' => pda_url, 'note' => note } ]
    return { :service => PDA, :iid => iids, :estimate => get_pda_delivery_time }
  end

  def _handle_ill holding
    iids = []
    return { :service => ILL, :iid => iids, :estimate => get_ill_delivery_time }
  end

  def _handle_ask_circulation holding
    iids = []
    return { :service => ASK_CIRCULATION, :iid => iids, :estimate => 9998 }
  end

  def _handle_ask_librarian
    iids = []
    return { :service => ASK_LIBRARIAN, :iid => iids, :estimate => 9999 }
  end

  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end

  AEON = 'aeon'

  def request_aeon target='aeon'
    resp, document = get_solr_response_for_doc_id(params[:id])
    bibid = params[:id]
    @isbn  = params[:isbn]
    @title = params[:title]
    logger.debug "Entering request_aeon #{bibid} \n\n"
    holdings_param = {
      :bibid => bibid
    }
    yholdings = get_holdings holdings_param
    @xholdings = (yholdings)[bibid]
    holdings = (yholdings) [bibid]['condensed_holdings_full']
    logger.debug "holdings #{bibid} \n\n"
    logger.debug holdings.inspect
    logger.debug "\n\n"
    holdings_parsed = {}
    @show_non_rare = false;
    holdings.each do |holding|
      if (!Aeon.eligible?(holding['location_code']))
         @show_non_rare = true
        logger.debug "\n\nset show_non_rare to #{@show_non_rare} \n\n"
      end
      holding['holding_id'].each do |holding_id|
        holdings_parsed[holding_id] = holding
      end
    end
    @h = holdings
    holdings_param[:type] = 'retrieve_detail_raw'
    raw = get_holdings holdings_param
    holdings_detail = raw[bibid]['records']
    logger.debug "\n\nholdings detail \n\n"
    logger.debug holdings_detail.inspect
    logger.debug "\n\n"
    item_types = get_item_types holdings_detail, bibid
    logger.debug "Item types :"
    logger.debug item_types.inspect
    logger.debug "\n\n"



    @request_solution = ''
    request_options = []
    holdings_detail.each do |holding|
      holding_id = holding['holding_id']

      holding_type = holding['item_status']['itemdata']
      if holding_type.count == 0
        next
      end
      holding_status = holding_type[0]['itemStatus']

      holdings_condensed_full_item = holdings_parsed[holding_id]
      logger.debug "status: #{holdings_condensed_full_item['status']}"
      ## is requested treated same as charged?
      item_status = get_item_status holding_status
      request_options.push( _handle_aeon bibid, holding )
    end
    if (!item_types.include?('aeon'))
       logger.debug "***Redirecting to see what happens \n\n"
       redirect_to request_item_redirect_path
       return;
     end
    request_options.push( _handle_ask_librarian )
    logger.debug "\n\n request options \n\n"
    logger.debug request_options.inspect
    logger.debug "\n\n"
    logger.debug "***Going to display to see what happens target is :#{target} \n\n"
    _display request_options, target , document
  end

  def aeon
    return request_aeon AEON
  end


  def _handle_aeon bibid, holding
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
    return { :service => AEON, :iid => iids, :estimate => 2 }
  end

 def get_item_types holdings_detail, bibid
    ## there are three types of loans
    ## regular
    ## day
    ## minute
    ## 'regular'
    types = []
    holdings_detail.each do |holding|
      if holding['bibid'] == bibid
        itemdata = holding['item_status']['itemdata']
        itemdata.each do |data|
          if (Aeon.eligible_id?(data['location_id']))
            logger.debug "Got aeon loan"
            types.push 'aeon'
          elsif IRREGULAR_LOAN_TYPE[:DAY][data['typeCode']] == 1
            logger.debug "Got day loan"
            types.push 'day'
          elsif IRREGULAR_LOAN_TYPE[:MINUTE][data['typeCode']] == 1
            logger.debug "Got minute loan"
            types.push 'minute'
          else
            logger.debug "Got regular loan"
            types.push 'minute'
          end
        end
      end
    end
    return types
  end

end
