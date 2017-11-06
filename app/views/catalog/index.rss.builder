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
      Rails.logger.ap doc.keys
      xml.item do
        xml.title(feed_item_title(doc))
        xml.link(polymorphic_url(doc))
        xml.content(feed_item_content(doc))
#        acquired = acquired_date(doc)
#       Rails.logger.debug "acquired date: " + acquired.inspect
#        xml.pubDate =acquired.strftime('%a, %d %b %Y %H:%M:%S %z')
      end
    end
  }
}

Rails.logger.level = saved_logger_level
