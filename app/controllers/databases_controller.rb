# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension
  
  def index
     clnt = HTTPClient.new
#     @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22anthropology+%28core%29%22&wt=ruby&indent=true") # do |chunk|
     @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databasesBySubject?q=Anthropology&wt=ruby&indent=true") # do |chunk|
       @anthropologyResponse = eval(@anthroString)
       @anthropology = @anthropologyResponse['response']['docs']
      @psychologyString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22psychology+%28core%29%22&wt=ruby&indent=true")
       @psychologyResponse = eval(@psychologyString)
       @psychology = @psychologyResponse['response']['docs']
      @dictionariesString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22dictionaries+and+encyclopedias+%28core%29%22&wt=ruby&indent=true")
       @dictionariesResponse = eval(@dictionariesString)
       @dictionaries = @dictionariesResponse['response']['docs']
      @libinfosciString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22library+and+information+science+%28core%29%22&wt=ruby&indent=true")
       @libinfosciResponse = eval(@libinfosciString)
       @libinfosci = @libinfosciResponse['response']['docs']       
    end
 
    
  def title
        clnt = HTTPClient.new
        @aString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databaseAlphaBuckets?q=#{params[:alpha]}#")
        @aResponse = eval(@aString)
        @a = @aResponse['response']['docs']
    end
 
  def searchdb
    Rails.logger.info("Petunia = #{params[:q]}")
     dbclnt = HTTPClient.new
     @dbResultString = dbclnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=" + params[:q] + "&wt=ruby&indent=true&defType=dismax")
     if !@dbResultString.nil?
       @dbResponseFull = eval(@dbResultString)
     else
       @dbResponseFull = eval("Could not find")
     end
     @dbResponse = @dbResponseFull['response']['docs']
  end
  
end 
