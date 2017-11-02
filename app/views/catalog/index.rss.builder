
saved_logger_level = Rails.logger.level
Rails.logger.level = 0
Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: in  catalog index.rss.builder"
Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: params: " + params.inspect

xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {

  xml.channel {

    xml.title(t('blacklight.search.title', :application_name => application_name))
    xml.link(url_for(params.merge(:only_path => false)))
    xml.description(t('blacklight.search.title', :application_name => application_name))
    xml.language('en-us')
    @document_list.each do |doc|
      semantic = doc.to_semantic_values
      Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: semantic: " + semantic.inspect
      xml.item do
        xml.title( doc.to_semantic_values[:title][0] || doc.id )
        xml.link(polymorphic_url(doc))
        description = ''
        description += doc.to_semantic_values[:author][0] if doc.to_semantic_values[:author][0]
        description += doc.to_semantic_values[:format][0] if doc.to_semantic_values[:format][0]
        xml.description! description if description
      end
    end

  }
}

Rails.logger.level = saved_logger_level
