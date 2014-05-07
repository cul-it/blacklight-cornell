# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension
  
  def subject
     clnt = HTTPClient.new
    params[:q].gsub!(' ','%20')
#     @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22anthropology+%28core%29%22&wt=ruby&indent=true") # do |chunk|
     @subjectString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databasesBySubject?q=\"" + params[:q] + "\"&wt=ruby&indent=true")
       @subjectResponse = eval(@subjectString)
       @subject = @subjectResponse['response']['docs']

    @subjectCoreString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databasesBySubject?q=\"" + params[:q] + "+(Core)\"&wt=ruby&indent=true")
    @subjectCoreResponse = eval(@subjectCoreString)
    @subjectCore = @subjectCoreResponse['response']['docs']
     params[:q].gsub!('%20', ' ')
   
    end
 
    
  def title
        clnt = HTTPClient.new
        @aString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databaseAlphaBuckets?q=#{params[:alpha]}#")
        @aResponse = eval(@aString)
        @a = @aResponse['response']['docs']
    end


      def show
        clnt = HTTPClient.new
        @dbString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/database?id=#{params[:id]}")
        @dbResponse = eval(@dbString)
        @db = @dbResponse['response']['docs']
    end

    
 
  def searchdb
    Rails.logger.info("Petunia1 = #{params[:q]}")
    params[:q].gsub!(' ','%20')
    Rails.logger.info("Petunia2 = #{params[:q]}")
     dbclnt = HTTPClient.new
     @dbResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
     if !@dbResultString.nil?
       @dbResponseFull = eval(@dbResultString)
     else
       @dbResponseFull = eval("Could not find")
     end
     @dbResponse = @dbResponseFull['response']['docs']
     params[:q].gsub!('%20', ' ')
    Rails.logger.info("Petunia3 = #{params[:q]}")
  end
  
end 
