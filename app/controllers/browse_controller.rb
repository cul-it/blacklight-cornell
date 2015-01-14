# -*- encoding : utf-8 -*-
class BrowseController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  #include BlacklightUnapi::ControllerExtension

    def index

      if !params[:q].nil? and params[:q] != "" and params[:browse_type] == "Author"
        #Rails.logger.info("Petunia1 = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:q]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:q] +'" TO *]' }
        start = {"start" => params[:start]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:q] +'"}' }

          @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a7/authorsR?" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a7/authors?" + p.to_param + '&' + start.to_param  )
        end
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:q].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:q]}")
      end

      if !params[:q].nil? and params[:q] != "" and params[:browse_type] == "Subject"
        #Rails.logger.info("Petunia1 = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:q]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:q] +'" TO *]' }
        start = {"start" => params[:start]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:q] +'"}' }

          @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a7/subjectsR?" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a7/subjects?" + p.to_param + '&' + start.to_param  )
        end
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
    def info
      if !params[:q].nil? and params[:q] != ""
        #Rails.logger.info("Petunia1 = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:q]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '"' + params[:q] +'"' } 
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
        @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a7/authors?" + p.to_param )
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:q].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:q]}")
      end

      if !params[:q].nil? and params[:q] != "" and params[:browse_type] == "Subject"
        #Rails.logger.info("Petunia1 = #{params[:q]}")
        #params[:q].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:q]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '"' + params[:q] +'"' } 
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
        @headingsResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/a7/subjects?" + p.to_param )
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