require_dependency "blacklight_cornell_requests/application_controller"

module BlacklightCornellRequests

  class RequestController < ApplicationController

    include Blacklight::SolrHelper
    include Cornell::LDAP

    def magic_request target=''

      @id = params[:bibid]
      resp, @document = get_solr_response_for_doc_id(@id)

      req = BlacklightCornellRequests::Request.new(@id)
      req.netid = request.env['REMOTE_USER']
      req.magic_request @document, request.env['HTTP_HOST'], {:target => target, :volume => params[:volume]}

      if ! req.service.nil?
        @service = req.service
      else
        @service = { :service => BlacklightCornellRequests::Request::ASK_LIBRARIAN }
      end

      @estimate = req.estimate
      @ti = req.ti
      @au = req.au
      @isbn = req.isbn
      @ill_link = req.ill_link
      @pub_info = req.pub_info
      @volume = params[:volume]
      @netid = req.netid
      @name = get_patron_name req.netid

      @iis = ActiveSupport::HashWithIndifferentAccess.new

      # @volumes = req.set_volumes(req.all_items)
      @volumes = req.volumes
      if req.volumes.present? and params[:volume].blank?
        if req.volumes.count != 1
          render 'shared/_volume_select'
          return
        else
          # a bit hacky solution here to get to request path
          # will need more rails compliant solution down the road...
          redirect_to '/request' + request.env['PATH_INFO'] + "/#{req.volumes[req.volumes.keys[0]]}"
          return
        end
      elsif req.request_options.present?
        req.request_options.each do |item|
          iid = item[:iid]
          iid[:call_number] = iid[:callNumber]
          @iis[iid[:itemid]] = iid
        end
        @volumes = req.volumes

        @alternate_request_options = []
        req.alternate_options.each do |option|
          @alternate_request_options.push({:option => option[:service], :estimate => option[:estimate]})
        end

      end

      render @service


    end

    # These one-line service functions simply return the name of the view
    # that should be rendered for each one.
    def l2l
      return magic_request Request::L2L
    end

    def hold
      return magic_request Request::HOLD
    end

    def recall
      return magic_request Request::RECALL
    end

    def bd
      return magic_request Request::BD
    end

    def ill
      return magic_request Request::ILL
    end

    def purchase
      return magic_request Request::PURCHASE
    end

    def pda
      return magic_request Request::PDA
    end

    def ask
      return magic_request Request::ASK_LIBRARIAN
    end

    def document_delivery
      return magic_request Request::DOCUMENT_DELIVERY
    end

    def blacklight_solr
      @solr ||=  RSolr.connect(blacklight_solr_config)
    end

    def blacklight_solr_config
      Blacklight.solr_config
    end

    def make_voyager_request

      # Validate the form data
      if params[:holding_id].blank?
        flash[:error] = I18n.t('requests.errors.holding_id.blank')
      elsif params[:library_id].blank?
        flash[:error] = I18n.t('requests.errors.library_id.blank')
      else
        # Hand off the data to the request model for sending
        req = BlacklightCornellRequests::Request.new(params[:bibid])
        req.netid = request.env['REMOTE_USER']
        response = req.make_voyager_request params

        if response[:failure].blank?
          # Note: the :flash=>'success' in this case is not setting the actual flash message,
          # but instead specifying a URL parameter that acts as a flag in Blacklight's show.html.erb view.
          render js: "window.location = '#{Rails.application.routes.url_helpers.catalog_path(params[:bibid], :flash=>'success')}'"
          return
        else
          flash[:error] = I18n.t('requests.failure')
        end
      end

      render :partial => '/flash_msg', :layout => false

    end

    def make_purchase_request

      if params[:name].blank?
        flash[:error] = I18n.t('requests.errors.name.blank')
      elsif params[:reqstatus].blank?
        flash[:error] = I18n.t('requests.errors.status.blank')
      elsif params[:reqtitle].blank?
        flash[:error] = I18n.t('requests.errors.title.blank')
      elsif params[:email].blank?
        flash[:error] = I18n.t('requests.errors.email.blank')
      elsif params[:email].present?
        if params[:email].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
          # Email the form contents to the purchase request staff
          RequestMailer.email_request(request.env['REMOTE_USER'], params)
          # TODO: check for mail errors, don't assume that things are working!
          flash[:success] = I18n.t('blacklight.requests.success')
        else
          flash[:error] = I18n.t('requests.errors.email.invalid')
        end
      end

      render :partial => '/flash_msg', :layout => false

    end

  end

end
