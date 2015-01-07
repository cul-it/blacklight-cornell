# -*- encoding : utf-8 -*-
class HeadingsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  #include BlacklightUnapi::ControllerExtension

    def authors
      if params[:q].nil? or params[:q] == ""
        flash.now[:error] = "Please enter a query."
        render "index"
      end
      if !params[:q].nil? and params[:q] != ""
        #Rails.logger.info("Petunia1 = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:q]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:q] +'" TO *]' } 
        start = {"start" => params[:starts]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
        @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a3/authors?" + p.to_param + '&' + start.to_param )
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:q].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:q]}")
      end
    end


end