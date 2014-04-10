# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  
  include Blacklight::Catalog
  include Blacklight::SolrHelper

  def show
    databasesHash = {}
    output = []
    @presortArray = []
#    @toc = JSON.parse(HTTPClient.get_content("http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/#{params[:id]}"))[params[:id]]
     clnt = HTTPClient.new
     databases = clnt.get_content("http://da-dev-solr.library.cornell.edu/solr/blacklight/select?q=%22anthropology+%28core%29%22&wt=ruby&indent=true") # do |chunk|
       dbArray = eval(databases)
       i = 0
       dbArray['response']['docs'].each do |doctary|
         @presortArray[i] = [doctary['id'], doctary['title_display']]
         i = i + 1
       end
       @presortArray.sort_by! {|e| e[2]}
       Rails.logger.info("DBKINDA= #{@presortArray}}")
       @printArray = ""
#        tocArray['response']['docs'].each do |doc|
        @presortArray.each do |doc|
#         pageNum = doc['id'].split('_')[1]
         pageNum = doc[0]
#         if doc[3].include? "."
            @printArray << "&nbsp;&nbsp;&nbsp;<a href='http://jac244-dev.library.cornell.edu/catalog/" + pageNum + "'>" + doc[1] + "</a><br>"      
#         printArray << "<a href='" + page_reader_url + pid + "/#page/" + pageNum + "/mode/1up'>" + doc['head_tesim'][0] + "</a><br>"
#         else      
#            printArray << "<a href='" + page_reader_url + pid + "/#page/" + pageNum + "/mode/1up'>" + doc[1] + "</a><br>"
#         end      
       end
  end
  
end