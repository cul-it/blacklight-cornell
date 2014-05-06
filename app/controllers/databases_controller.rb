# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  
  def index
     clnt = HTTPClient.new
#     @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22anthropology+%28core%29%22&wt=ruby&indent=true") # do |chunk|
     @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=anthropology&wt=ruby&indent=true") # do |chunk|
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
  
end 
