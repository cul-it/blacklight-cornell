# -*- encoding : utf-8 -*-
class BamwowController < ApplicationController
  include ExternalDataHelper
 
  require 'net/http'

  def heading
   @heading='Browse'
  end
  #Get  
  #Arguments: base url, authority type (author or subject), query string 
  def get_browse_info
    authq = params[:q] || ""
    browse_index_authortitle = ENV['BROWSE_INDEX_AUTHORTITLE'].nil? ? 'authortitle' : ENV['BROWSE_INDEX_AUTHORTITLE'] 
    base_solr = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
    query_url = base_solr + '/' + browse_index_authortitle + '/browse?wt=json&q='
  	result = nil
    if(authq != "")
      p =  {"q" => authq.gsub("\\"," ").gsub("%26", "&")}
      query_url = query_url + p.to_param
      url = URI.parse(query_url)
      resp = Net::HTTP.get_response(url)
      data = resp.body
      results = JSON.parse(data)
      # Return results[docs]
      if(results.key?("response") && results["response"].key?("docs") && results["response"]["docs"].length > 0)
        result = results["response"]["docs"]
      end
    end
    render :json => result
  end
  # Get info to display in knowledge panel
  # Arguments: base url, authority type (author or subject), query string 
 	
  def index
  	
  end

 
end