# -*- encoding : utf-8 -*-
class AeonController < ApplicationController
  
  include Blacklight::Catalog
  
  def request_aeon
    #resp, document = get_solr_response_for_doc_id(params[:bibid])
    resp, document = fetch (@id) 
    aeon = Aeon.new
    request_options, target, @holdings = aeon.request_aeon document, params
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
    
    @service = service

    render service
  end
  
  def sort_request_options request_options
    return request_options.sort_by { |option| option[:estimate] }
  end
  
end
