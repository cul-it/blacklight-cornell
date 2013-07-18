# -*- encoding : utf-8 -*-
class AeonController < ApplicationController
  
  include Blacklight::Catalog
  
  def request_aeon
    begin
      return _request_aeon
    rescue => e
      sk274_log "Exception #{e.class.name} : #{e.message}"
      return nil
    end
  end
  
  def _request_aeon
    sk274_log "i am called with bibid: #{params[:bibid]}"
    
    resp, document = get_solr_response_for_doc_id(params[:bibid])
    aeon = Aeon.new
    request_options, target, @holdings = aeon.request_aeon document, params
    
    sk274_log "request options: #{request_options.inspect}"
    sk274_log "target: #{target}"
    
    _display request_options, target, document
  end
  
  def _display request_options, service, doc
    @document = doc
    @ti = @document[:title_display]
    @au = @document[:author_display]
    @isbn = @document[:isbn_display]
    @id = params[:bibid]
    @iis = {}
    @alternate_request_options = []
    seen = {}
    request_options.each do |item|
      if item[:service] == service
        @estimate = item[:estimate]
        iids = item[:iid]
        iids.each do |iid|
          @iis[iid['itemid']] = {
            :location => iid['location'],
            :location_id => iid['location_id'],
            :call_number => iid['callNumber'],
            :copy => iid['copy'],
            :enumeration => iid['enumeration'],
            :url => iid['url'],
            :chron => iid['chron'],
            :exclude_location_id => iid['exclude_location_id']
          }
        end
      else
        if ! seen[item[:service]] || seen[item[:service]] > item[:estimate]
          seen[item[:service]] = item[:estimate]
        end
      end
    end

    seen.each do |service, estimate|
      @alternate_request_options.push({ :option => service, :estimate => estimate})
    end
    @alternate_request_options = sort_request_options @alternate_request_options

    sk274_log @iis.inspect
    sk274_log "service: #{service}"
    
    @service = service
    
    sk274_log "rendering #{service}..."

    render service
  end
  
  def sort_request_options request_options
    return request_options.sort_by { |option| option[:estimate] }
  end
  
  def sk274_log msg
    Rails.logger.info "sk274_log: #{msg}"
  end
end