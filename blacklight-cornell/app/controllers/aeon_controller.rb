# frozen_string_literal: true

class AeonController < ApplicationController
  # NOTE: This layout is redundant at this point. But a layout must be specified, and using the standard Blacklight
  # layout adds a header and footer that are not present in the current production version.
  layout 'aeon'
  include Blacklight::Catalog

  def reading_room; end

  def index; end

  def reading_room_request
    set_variables
  end

  def scan_aeon
    set_variables
  end

  def set_variables
    # @finding_aid = params[:finding] || ''
    @bibid = params[:id]
    _, @document = search_service.fetch(params[:id])
    @title = @document['fulltitle_display']
    @author = @document['author_display']
    @re506 = @document['restrictions_display']&.first&.delete_suffix("'") || ''
    @finding_aids = @document['url_findingaid_display']
    @disclaimer = 'Once your order is reviewed by our staff you will then be sent an invoice. ' \
    'Your invoice will include information on how to pay for your order. You must pre-pay; ' \
    'staff cannot fulfill your request until you pay the charges.'
    @aeon_request = AeonRequest.new(@document)
    session[:current_user_id] = 1
  end

end
