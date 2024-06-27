# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class AeonController < ApplicationController
  layout 'aeon/index'
  include Blacklight::Catalog

  @ic = 0
  @bcc = 0
  @bibid = ''
  @title = ''
  @warning = ''

  def reading_room
    @url = 'www.google.com'
  end

  def index
    @url = 'www.google.com'
    @review_text = 'Keep this request saved in your account for later review.' \
    ' It will not be sent to library staff for fulfillment.'
  end

  def new_aeon_login; end

  # rewrite of monograph.php from voy-api.library.cornell.edu
  def reading_room_request
    set_rr_instance_variables
    set_rr_vars_from_document
    set_holdings_and_items
    set_messages
    session[:current_user_id] = 1
  end

  def scan_aeon
    set_scan_instance_variables
    set_scan_vars_from_document
    set_holdings_and_items
    set_messages
    session[:current_user_id] = 1
  end

  def set_rr_instance_variables
    @finding_aid = params[:finding] || ''
    @url = 'http://www.googles.com'
    @bibid = params[:id]
    @doctype = 'Manuscript'
    # @aeon_type = 'GenericRequestManuscript'
    @webreq = 'GenericRequestManuscript'
    # @this_sub = '' # this is the submitter, but the 'submitter' variable doesn't seem to be used anywhere else
    @the_loginurl = loginurl
  end

  def set_rr_vars_from_document
    _, @document = search_service.fetch(params[:id])
    # @bibdata = make_bibdata(@document)
    # @bibdata_string = @bibdata.to_s
    @title = @document['fulltitle_display']
    @author = @document['author_display']
    @re506 = @document['restrictions_display']&.first || ''
  end

  def set_holdings_and_items
    @aeon_request = AeonRequest.new(@document)
    # holdings_json_hash = Hash(JSON.parse(@document['holdings_json']))
    # items_json_hash = @document['items_json'] ? Hash(JSON.parse(@document['items_json'])) : {}
    #holdings_json_hash = aeon_request.holdings
    #items_json_hash = aeon_request.items
    #@ho = holdings(holdings_json_hash, items_json_hash)
  end

  def set_messages
    @disclaimer = 'Once your order is reviewed by our staff you will then be sent an invoice. ' \
    'Your invoice will include information on how to pay for your order. You must pre-pay; ' \
    'staff cannot fulfill your request until you pay the charges.'
    @schedule_text = 'Select a date to visit. Materials held on site are available immediately; ' \
    'off-site items require scheduling 2 business days in advance, as indicated above. ' \
    'Please be sure that you choose a date when we are ' \
    '<a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
    @review_text = 'Keep this request saved in your account for later review. ' \
    'It will not be sent to library staff for fulfillment.'
    @quest_text = 'Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions.'
  end

  def set_scan_instance_variables
    @finding_aid = params[:finding] || ''
    @url = 'http://www.googles.com'
    @bibid = params[:id]
    # @this_sub = ''
    # @cart = selecter # this is the submitter, but the 'submitter' variable doesn't seem to be used anywhere else
    @the_loginurl = loginurl

    # TODO: Do we really need 3 instance vars that all say the same thing?
    @doctype = 'Photoduplication'
    # @aeon_type = 'PhotoduplicationRequest'
    @type = 'PhotoduplicationRequest'
    @webreq = 'Copy'
  end

  def set_scan_vars_from_document
    _, @document = search_service.fetch(params[:id])
    # @bibdata = make_bibdata(@document)
    @title = @document['fulltitle_display']
    @author = @document['author_display']
    @re506 = @document['restrictions_display']&.first&.delete_suffix("'") || ''
    @warning = warning(@title)
  end

  # def selecter
  #   '
  #     <div id="shoppingcart">
  #     <span id="numitems">Number of items selected:</span>
  #     <span id="num-selections-wrapper">
  #     <span id="num-selections">
  #     </span>
  #     </span>

  #     <div id="selections-wrapper">
  #     <ol><div id="selections"></div>
  #     </ol>
  #     </div>
  #     </div>
  #   '
  # end

  def loginurl
    '/aeon/aeon_login'
    # 	return "http://dev-jac2445.library.cornell.edu/aeon511/aeon-login.php"
    # 	return "http://voy-api.library.cornell.edu/aeon/aeon_test-login.php"
  end

  def warning(title)
    if title.include?('[electronic resource]')
      'There is an electronic version of this resource -- do you really want to request this?'
    else
      ''
    end
  end

  # def clearer
  #   '
  #     <div class="control-group">
  #     <label class="control-label sr-only" for="SubmitButton">Submit request</label>
  #     <input type="submit" class="btn btn-dark" id="SubmitButton" name="SubmitButton" value="Submit Request">
  #     <label class="control-label sr-only" for="clear">Clear</label>
  #     <input type="button" class="btn btn-secondary" id="clear"  name="clear" value="Clear Form">
  #     <br/>' + @quest_text + '<br/>
  #     </div>
  #   '
  # end

  # def former
  #   '</form>'
  # end

  # def submitter
  #   ''
  # end

  # def xsubmitter
  #   '
  #       <div class="control-group">
  #       <div class="controls">
  #       <label class="control-label sr-only" for="SubmitButton">Submit request</label>
  #       <input type="submit" class="btn" id="SubmitButton" name="SubmitButton" value="Submit Request">
  #       </div>
  #       </div>
  #   '
  # end

  def login
    'woops'
  end

  # redirect_shib is redefined later in the class.
  # def redirect_shib
  #   redirect_to 'https://rmc-aeon.library.cornell.edu'
  # end

  # NOTE: This function doesn't seem to do anything useful - it always returns a static string for bibdata_output_hash,
  # and that string doesn't appear to be used anywhere else in the code.
  # def make_bibdata(document)
  #   holding_id = ''
  #   publisher = document['publisher_display'][0] || ''
  #   pubdate = document['pub_date_display'][0] || ''
  #   pubplace = document['pubplace_display'][0] || ''
  #   holdings_json = Hash(JSON.parse(document['holdings_json']))

  #   firstkeyout = ''
  #   count = 0
  #   bibdata_output_hash = '{"items": [{"author":null,"title":null,"pub_place":null,"publisher":null,"publisher_date":null,"edition":null,"bib_format":null,"permlocation":null,"permlocationcode":null,"holdings":[]}]}'
  #   if !document['items_json'].nil?
  #     bibdata_hash = Hash(JSON.parse(document['items_json']))
  #     bibdata_hash.each do | firstKey, value |
  #       if count == 0
  #         firstkeyout = firstKey
  #         count = count + 1
  #         valueHash = Hash(value[0])
  #         # 	        bibdata_output_hash = bibdata_output_hash + firstkeyout + '":['
  #       end
  #     end
  #   end
  #   if firstkeyout != ''
  #     callnum = holdings_json[firstkeyout]['call']
  #   else
  #     callnum = ''
  #   end

  #   if !document['items_json'].nil?
  #     bibdata_hash.each do | key, value |
  #       #	if count == 0
  #       holding_id = key
  #       valueArray = value.to_a
  #       valueArray.each do | key, hold |
  #       valueHash = Hash(hold)
  #       keyout = Hash[key]
  #     end
  #   end
  # end

  # return bibdata_output_hash
  # end

  def aeon_login
    params
  end

  def redirect_nonshib
    @outbound_params = params
  end

  def boom; end

  def redirect_shib
    #     @user = User.new()
    #    @session = Session.new()
    #     session.user = "jac244"
    #        uri = URI('https://rmc-aeon.library.cornell.edu/aeon/aeon.dll')
    #        res = Net::HTTP.get_response(uri)
    #       Rails.logger.info("COOOKIE = #{cookies.inspect}")
    #       Rails.logger.info("RESBODY= #{res.body if res.is_a?(Net::HTTPSuccess)}")
    #        response = HTTParty.get('https://rmc-aeon.library.cornell.edu/aeon/boom.html?target=https://catalog-folio-int.library.cornell.edu')
    #       Rails.logger.info("HTTPARTY = #{response}")
    #       Rails.logger.info("COOOKIE = #{cookies.inspect}")
    @outbound_params = params
  end
end
# rubocop:enable Metrics/ClassLength
