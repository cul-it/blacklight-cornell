# -*- encoding : utf-8 -*-
class KpanelController < ApplicationController
  include ExternalDataHelper
 
  require 'net/http'

  #attr_accessible :authq, :start, :order, :browse_type
  @@browse_index_author = ENV['BROWSE_INDEX_AUTHOR'].nil? ? 'author' : ENV['BROWSE_INDEX_AUTHOR']
  @@browse_index_subject = ENV['BROWSE_INDEX_SUBJECT'].nil? ? 'subject' : ENV['BROWSE_INDEX_SUBJECT']
  @@browse_index_authortitle = ENV['BROWSE_INDEX_AUTHORTITLE'].nil? ? 'authortitle' : ENV['BROWSE_INDEX_AUTHORTITLE']

  def heading
   @heading='Browse'
  end
  #Get  
  #Arguments: base url, authority type (author or subject), query string 
  def get_browse_info(authq, auth_type)
  	result = nil
    if(auth_type != "" && authq != "")
      p =  {"q" => authq.gsub("\\"," ").gsub("%26", "&")}
      base_solr_url = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr/')
      query_url = base_solr_url + browse_type(auth_type) + '/browse?wt=json&' + p.to_param
      url = URI.parse(query_url)
      resp = Net::HTTP.get_response(url)
      data = resp.body
      results = JSON.parse(data)
      # Return results[docs]
      if(results.key?("response") && results["response"].key?("docs") && results["response"]["docs"].length > 0)
        result = results["response"]["docs"]
      end
    end
    return result
  end
  # Get info to display in knowledge panel
  # Arguments: base url, authority type (author or subject), query string 
  def panel
    return unless ['author', 'subject', 'authortitle'].include?(params[:type])

    @authq = params[:authq] || ''
    @auth_type = params[:type] || ''
    # This should return the JSON for solr documents
    results = get_browse_info(@authq, @auth_type)
    @data = results[0]

    if ['author', 'subject'].include?(@auth_type)
      heading = @data['heading']
      #Call helper method to see whether external data should or should not be included within panel
      #This used to be @authq but changing it because the parameter from the link may have different
      #ending punctuation than the heading in the browse.  Relying entirely on heading now
      permissions_key = heading.delete_prefix('"').delete_suffix('"')
      @exclusions = check_permissions(permissions_key)
      render 'default_panel'
    elsif @auth_type == 'authortitle'
      render 'authortitle_panel'
    end
  end
  def index
  	
  end

  private

  def browse_type(auth_type)
    case auth_type
    when 'author'
      @@browse_index_author
    when 'subject'
      @@browse_index_subject
    when 'authortitle'
      @@browse_index_authortitle
    end
  end
end