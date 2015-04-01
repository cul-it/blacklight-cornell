# -*- encoding : utf-8 -*-
class DigitalcollectionsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension

  def index
     clnt = HTTPClient.new
    #params[:q].gsub!(' ','%20')
     @digRegString = clnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/blacklight/select?qt=search&rows=100&facet=false&wt=ruby&indent=true&fq=eightninenine_t:culdigreg&sort=title_sort%20asc&fl=id,fulltitle_display,author_display,pub_info_display,fulltitle_vern_display,summary_display,url_access_display") 
     @digRegResponse = eval(@digRegString)
     @digReg = @digRegResponse['response']['docs']
    end

   def searchdigreg
      if params[:q].nil? or params[:q] == ""
        flash.now[:error] = "Please enter a query."
        render "index"
      end
      if !params[:q].nil? and params[:q] != ""
        Rails.logger.info("Petunia1 = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        Rails.logger.info("Petunia2 = #{params[:q]}")
        dbclnt = HTTPClient.new
        Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        solr = Blacklight.solr_config[:url]
        p = {"q" =>params[:q] }
        Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
        @digregResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/blacklight/select?qt=search&" + p.to_param + "&rows=100&facet=false&wt=ruby&indent=true&fq=eightninenine_t:culdigreg&sort=title_sort%20asc&fl=id,fulltitle_display,author_display,pub_info_display,fulltitle_vern_display,summary_display,url_access_display")
        if !@digregResultString.nil?
           @digregResponseFull = eval(@digregResultString)
        else
           @digregResponseFull = eval("Could not find")
        end
        @digregResponse = @digregResponseFull['response']['docs']
        params[:q].gsub!('%20', ' ')
        Rails.logger.info("Petunia3 = #{params[:q]}")
      end
    end
end