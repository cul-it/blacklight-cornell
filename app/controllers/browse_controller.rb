# -*- encoding : utf-8 -*-
class BrowseController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  #include BlacklightUnapi::ControllerExtension
  before_filter :heading
  
  def heading
   @heading='Browse'
  end
    def index

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Author"
        #Rails.logger.info("Petunia1 = #{params[:authq]}")
        #params[:authq].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:authq]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:authq] +'" TO *]' }
        start = {"start" => params[:start]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:authq] +'"}' }

          @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/author/reverse?" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/author/browse?" + p.to_param + '&' + start.to_param )
        end
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:authq]}")
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Subject"
        #Rails.logger.info("Petunia1 = #{params[:authq]}")
        #params[:authq].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:authq]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:authq] +'" TO *]' }
        start = {"start" => params[:start]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:authq] +'"}' }

          @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/subject/reverse?" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/subject/browse?" + p.to_param + '&' + start.to_param  )
        end
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:authq]}")
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Author-Title"
        #Rails.logger.info("Petunia1 = #{params[:authq]}")
        #params[:authq].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:authq]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:authq] +'" TO *]' }
        start = {"start" => params[:start]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:authq] +'"}' }

          @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/authortitle/reverse?" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/authortitle/browse?" + p.to_param + '&' + start.to_param  )
        end
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:authq]}")
      end


    end
    def info
      if !params[:authq].nil? and params[:authq] != ""
        #Rails.logger.info("Petunia1 = #{params[:authq]}")
        #params[:authq].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:authq]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '"' + params[:authq] +'"' } 
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/author/browse?" + p.to_param )
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:authq]}")
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Subject"
        #Rails.logger.info("Petunia1 = #{params[:authq]}")
        #params[:authq].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:authq]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '"' + params[:authq] +'"' } 
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/subject/browse?" + p.to_param )
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:authq]}")
      end
      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Author-Title"
        #Rails.logger.info("Petunia1 = #{params[:authq]}")
        #params[:authq].gsub!(' ','%20')
        #Rails.logger.info("Petunia2 = #{params[:authq]}")
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '"' + params[:authq] +'"' } 
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        @headingsResultString = dbclnt.get_content("http://da-stg-ssolr.library.cornell.edu/solr/authortitle/browse?" + p.to_param )
        if !@headingsResultString.nil?
           @headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
        #Rails.logger.info("Petunia3 = #{params[:authq]}")
      end
    end

end