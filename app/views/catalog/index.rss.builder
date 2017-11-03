require "awesome_print"
saved_logger_level = Rails.logger.level
Rails.logger.level = 0
Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: in  catalog index.rss.builder"
Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: params: " + params.inspect

# subtitle the_vernaculator('subtitle_display', 'subtitle_vern_display')
# responsibility field_value 'title_responsibility_display'
#   published -- description
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
      semantics = doc.to_semantic_values
      title = semantics[:title].blank? ? doc.id : semantics[:title].first
      pub_disc = []
      pub_disc << doc['pub_info_display'].first unless doc['pub_info_display'].blank?
      pub_disc << 'description here'
      holdings_condensed = create_condensed_full(doc)
      col_loc = []
      col_loc << holdings_condensed[0]['call_number'] unless holdings_condensed[0]['call_number'].blank?
      col_loc << holdings_condensed[0]['location_name'] unless holdings_condensed[0]['location_name'].blank?
      Rails.logger.ap doc['fulltitle_display']
      xml.item do
        xml.title( title )
        xml.link(polymorphic_url(doc))
        description = Array.new
        description << doc['subtitle_display'] unless doc['subtitle_display'].blank?
        description << pub_disc.join(' -- ') unless pub_disc.blank?
        description << col_loc.join(' -- ') unless col_loc.blank?
        xml.description(description.join("<br \\>"))
      end
    end

  }
}

Rails.logger.level = saved_logger_level
