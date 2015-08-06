# -*- encoding : utf-8 -*-
class DigitalcollectionsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension
  before_filter :heading
  
  def heading
   @heading='Cornell Digital Collections'
  end

   def index
     clnt = HTTPClient.new
    #params[:q].gsub!(' ','%20')
    base_solr = Blacklight.solr_config[:url]
    Rails.logger.debug("es287_debug #{__FILE__} #{__LINE__}  = " + "#{base_solr}")
     @digRegString = clnt.get_content("#{base_solr}/select?qt=search&rows=100&facet=false&wt=ruby&indent=true&fq=eightninenine_t:culdigreg&sort=title_sort%20asc&fl=id,fulltitle_display,author_display,pub_info_display,fulltitle_vern_display,summary_display,url_access_display") 
     @digRegResponse = eval(@digRegString)
     @digReg = @digRegResponse['response']['docs']
    end

   def searchdigreg
      if params[:q].nil? or params[:q] == ""
        flash.now[:error] = "Please enter a query."
        render "index"
      end
      if !params[:q].nil? and params[:q] != ""
        Rails.logger.debug("#{__FILE__}:#{__LINE__}:params = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        Rails.logger.debug("#{__FILE__}:#{__LINE__}:params = #{params[:q]}")
        dbclnt = HTTPClient.new
        Rails.logger.debug("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        solr = Blacklight.solr_config[:url]
        p = {"q" =>params[:q] }
        Rails.logger.debug("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        @digregResultString = dbclnt.get_content("#{solr}/select?qt=search&" + p.to_param + "&rows=100&facet=false&wt=ruby&indent=true&fq=eightninenine_t:culdigreg&sort=title_sort%20asc&fl=id,fulltitle_display,author_display,pub_info_display,fulltitle_vern_display,summary_display,url_access_display")
        if !@digregResultString.nil?
           @digregResponseFull = eval(@digregResultString)
        else
           @digregResponseFull = eval("Could not find")
        end
        @digregResponse = @digregResponseFull['response']['docs']
        params[:q].gsub!('%20', ' ')
        Rails.logger.debug("#{__FILE__}:#{__LINE__}:params = #{params[:q]}")
      end
    end
end
