# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  
  def subject
     clnt = HTTPClient.new
      @anthroString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22Anthropology%22&&wt=ruby")
       @anthropologyResponse = eval(@anthroString)
       @anthropology = @anthropologyResponse['response']['docs']
      @anthroCoreString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22Anthropology+%28Core%29%22&&wt=ruby")
       @anthropologyCoreResponse = eval(@anthroCoreString)
       @anthropologyCore = @anthropologyCoreResponse['response']['docs']
      @psychologyString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22psychology+%28core%29%22&wt=ruby")
       @psychologyResponse = eval(@psychologyString)
       @psychology = @psychologyResponse['response']['docs']
      @statisticalString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22Computers+and+Information+Science%22&wt=ruby")
       @statisticalResponse = eval(@statisticalString)
       @statistical = @statisticalResponse['response']['docs']
      @libinfosciString = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/databases?q=%22library+and+information+science+%28core%29%22&wt=ruby")
       @libinfosciResponse = eval(@libinfosciString)
       @libinfosci = @libinfosciResponse['response']['docs']
       
    end
  
end
