# -*- encoding : utf-8 -*-
class BrowseController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  #include BlacklightUnapi::ControllerExtension
  before_filter :heading
  before_action :redirect_catalog
  #attr_accessible :authq, :start, :order, :browse_type
  @@browse_index_author = ENV['BROWSE_INDEX_AUTHOR'].nil? ? 'author' : ENV['BROWSE_INDEX_AUTHOR']
  @@browse_index_subject = ENV['BROWSE_INDEX_SUBJECT'].nil? ? 'subject' : ENV['BROWSE_INDEX_SUBJECT']
  @@browse_index_authortitle = ENV['BROWSE_INDEX_AUTHORTITLE'].nil? ? 'authortitle' : ENV['BROWSE_INDEX_AUTHORTITLE']
  @@browse_index_callnumber = ENV['BROWSE_INDEX_CALLNUMBER'].nil? ? 'callnum' : ENV['BROWSE_INDEX_CALLNUMBER']
  def heading
   @heading='Browse'
  end
    def index
        base_solr = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
        Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{base_solr}")

      Appsignal.increment_counter('browse_index', 1)
      authq = params[:authq]
      browse_type = params[:browse_type]
      if params[:start].nil?
        params[:start] = '0'
      end
      start = params[:start]
      if !authq.nil? and authq != "" and browse_type == "Author"
        dbclnt = HTTPClient.new
        p =  {"q" => '["' + authq.gsub("\\"," ").gsub('"',' ')+'" TO *]' }
        start = {"start" => start}
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + authq.gsub("\\"," ").gsub('"',' ')+'"}' }
#          @headingsResultString = dbclnt.get_content(base_solr + "/author/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
#          @headingsResultString = @headingsResultString
          @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_author + "/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_author + "/browse?&wt=json&" + p.to_param + '&' + start.to_param )
        end
        if !@headingsResultString.nil?
           y = @headingsResultString
           @headingsResponseFull = JSON.parse(y)
           #@headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Subject"
        dbclnt = HTTPClient.new
        p =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') + '" TO *]' }
        if params[:start].nil?
          params[:start] = '0'
        end
        start = {"start" => params[:start].gsub("\\"," ")}
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ')+'"}' }

          @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_subject + "/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_subject + "/browse?&wt=json&" + p.to_param + '&' + start.to_param  )
        end
        if !@headingsResultString.nil?
           y = @headingsResultString
           @headingsResponseFull = JSON.parse(y)
           #@headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Author-Title"
        dbclnt = HTTPClient.new
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
        #solr = Blacklight.solr_config[:url]
        p =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') +'" TO *]' }
        start = {"start" => params[:start]}
        #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{solr}/databases?"+p.to_param)
        #@dbResultString = dbclnt.get_content("#{solr}/databases?q=" + params[:authq] + "&wt=ruby&indent=true&defType=dismax")
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ')+'"}' }
          @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_authortitle + "/reverse?&wt=json&" + p.to_param + '&' + start.to_param  )
          @headingsResultString = @headingsResultString
        else
          @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_authortitle + "/browse?wt=json&" + p.to_param + '&' + start.to_param  )
        end
        if !@headingsResultString.nil?
           y = @headingsResultString
           @headingsResponseFull = JSON.parse(y)
           #@headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Call-Number"
        # http://da-prod-solr.library.cornell.edu/solr/callnum/browse?q=%7B!tag=mq%7D%5B%22HD8011%22%20TO%20*%5D
        call_no_solr = base_solr
        start = {"start" => params[:start]}
        dbclnt = HTTPClient.new
        if params[:order] == "reverse"
          p =  {"q" => '[* TO "' + params[:authq].gsub("\\"," ").gsub('"',' ') +'"}' }
          url = call_no_solr + "/" + @@browse_index_callnumber + "/reverse?wt=json&" + p.to_param + '&' + start.to_param 
        else
          p =  {"q" => '["' + params[:authq].gsub("\\"," ").gsub('"',' ') +'" TO *]' }
          url = call_no_solr + "/" + @@browse_index_callnumber + "/browse?wt=json&" + p.to_param + '&' + start.to_param 
        end
        if params[:fq]
          url = url + '&fq=' + params[:fq]
        end
        @headingsResultString = dbclnt.get_content( url )
        if !@headingsResultString.nil?
          y = @headingsResultString
          @headingsResponseFull = JSON.parse(y)
       else
          @headingsResponseFull = eval("Could not find")
       end
       @headingsResponse = @headingsResponseFull
       params[:authq].gsub!('%20', ' ')
       #Rails.logger.info("jgr25_debug #{__FILE__} #{__LINE__}  = headingResponse: " + @headingsResponse.inspect )
      end

    end
    def info
      if !params[:authq].present? || !params[:browse_type].present?
        flash.now[:error] = "Please enter a complete query."
        render "index"
      else
        base_solr = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
        Appsignal.increment_counter('browse_info', 1)
        Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = " + "#{base_solr}")
      if !params[:authq].nil? and params[:authq] != ""
        dbclnt = HTTPClient.new
        p =  {"q" => '"' + params[:authq].gsub("\\"," ") +'"' }
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_author + "/browse?wt=json&" + p.to_param )
        if !@headingsResultString.nil?
           y = @headingsResultString
           @headingsResponseFull = JSON.parse(y)
           #@headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
      end

      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Subject"
        dbclnt = HTTPClient.new
        p =  {"q" => '"' + params[:authq].gsub("\\"," ") +'"' }
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_subject + "/browse?wt=json&" + p.to_param )
        if !@headingsResultString.nil?
           y = @headingsResultString
           @headingsResponseFull = JSON.parse(y)
           #@headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
      end
      if !params[:authq].nil? and params[:authq] != "" and params[:browse_type] == "Author-Title"
        dbclnt = HTTPClient.new
        p =  {"q" => '"' + params[:authq].gsub("\\"," ") +'"' }
        @headingsResultString = dbclnt.get_content(base_solr + "/" + @@browse_index_authortitle + "/browse?wt=json&" + p.to_param )
        if !@headingsResultString.nil?
           y = @headingsResultString
           @headingsResponseFull = JSON.parse(y)
           #@headingsResponseFull = eval(@headingsResultString)
        else
           @headingsResponseFull = eval("Could not find")
        end
        @headingsResponse = @headingsResponseFull['response']['docs']
        params[:authq].gsub!('%20', ' ')
      end
      respond_to do |format|
        format.html { render layout: !request.xhr? } #renders naked html if ajax
      end
    end
end

def redirect_catalog
  if params[:browse_type]
    if params[:browse_type].include?('catalog')
      field=params[:browse_type].split(':')[1]
      redirect_to "/catalog?q=#{CGI.escape params[:authq]}&search_field=#{field}"
    end
  end
end
end
