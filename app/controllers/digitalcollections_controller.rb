# -*- encoding : utf-8 -*-
class DigitalcollectionsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension
  before_filter :heading

  def heading
   @heading='Digital Collections'
  end

   def index
     clnt = HTTPClient.new
    #params[:q].gsub!(' ','%20')
    base_solr = Blacklight.connection_config[:url]
    Rails.logger.debug("es287_debug #{__FILE__} #{__LINE__}  = " + "#{base_solr}")
     @digRegString = clnt.get_content("#{base_solr}/culdigreg?q=*")
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
        Rails.logger.debug("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.connection_config.inspect}")
        solr = Blacklight.connection_config[:url]
        p = {"q" =>params[:q] }
        Rails.logger.debug("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/culdigreg?" + p.to_param)
        @digregResultString = dbclnt.get_content("#{solr}/culdigreg?" + p.to_param)
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
