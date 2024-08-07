# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class AeonController < ApplicationController
  layout 'aeon'
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
    @aeon_request = AeonRequest.new(@document)
    set_messages
    session[:current_user_id] = 1
  end

  def scan_aeon
    set_scan_instance_variables
    set_scan_vars_from_document
    @aeon_request = AeonRequest.new(@document)
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

  def loginurl
    '/aeon/aeon_login'
  end

  def warning(title)
    if title.include?('[electronic resource]')
      'There is an electronic version of this resource -- do you really want to request this?'
    else
      ''
    end
  end

  def login
    'woops'
  end

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
