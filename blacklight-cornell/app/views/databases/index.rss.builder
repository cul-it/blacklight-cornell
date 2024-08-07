xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {
        
  xml.channel {
          
    xml.title(t('blacklight.search.title', :application_name => application_name))
    xml.link(databases_searchdb_url(params))
    xml.description(t('blacklight.search.title', :application_name => application_name))
    xml.language('en-us')
    @document_list.each do |doc|
      xml.item do  
        xml.title( doc.to_semantic_values[:title][0] || doc.id )                              
        xml.link(databases_show_path(doc.id))                                   
        xml.author( doc.to_semantic_values[:author][0] ) if doc.to_semantic_values[:author][0]       
      end
    end
          
  }
}
