require "awesome_print"
saved_logger_level = Rails.logger.level
Rails.logger.level = 0
Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: in  catalog index.rss.builder"
Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: params: " + params.inspect

# subtitle the_vernaculator('subtitle_display', 'subtitle_vern_display')
# responsibility field_value 'title_responsibility_display'
# call number - location
# holdings_condensed = create_condensed_full(@document)

xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {

  xml.channel {

    xml.title(t('blacklight.search.title', :application_name => application_name))
    xml.link(url_for(params.merge(:only_path => false)))
    xml.description(t('blacklight.search.title', :application_name => application_name))
    xml.language('en-us')
    @document_list.each do |doc|
      #Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: doc: " + doc.inspect
      holdings_condensed = create_condensed_full(doc)
      call_number = holdings_condensed[0]['call_number']
      location = holdings_condensed[0]['location_name']
      Rails.logger.ap doc.inspect
      xml.item do
        xml.title( doc.to_semantic_values[:title][0] || doc.id )
        xml.link(polymorphic_url(doc))
        description = Array.new
        description << doc.to_semantic_values[:author][0] if doc.to_semantic_values[:author][0]
        description << doc.to_semantic_values[:format][0] if doc.to_semantic_values[:format][0]
        description <<  doc['subtitle_display'] if doc['subtitle_display']
        description <<  call_number + ' ' + location
        xml.description(description) if description.join(" \n")
      end
    end

  }
}

Rails.logger.level = saved_logger_level
