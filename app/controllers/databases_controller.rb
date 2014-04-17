# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  
  def subject
     clnt = HTTPClient.new
      @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=anthropology&wt=ruby")
       @anthropologyResponse = eval(@anthroString)
       @anthropology = @anthropologyResponse['response']['docs']
      @psychologyString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22psychology+%28core%29%22&wt=ruby")
       @psychologyResponse = eval(@psychologyString)
       @psychology = @psychologyResponse['response']['docs']
      @dictionariesString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22dictionaries+and+encyclopedias+%28core%29%22&wt=ruby")
       @dictionariesResponse = eval(@dictionariesString)
       @dictionaries = @dictionariesResponse['response']['docs']
      @libinfosciString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22library+and+information+science+%28core%29%22&wt=ruby")
       @libinfosciResponse = eval(@libinfosciString)
       @libinfosci = @libinfosciResponse['response']['docs']
       
    end
  
end
