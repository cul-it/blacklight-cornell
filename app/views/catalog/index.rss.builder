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
    xml.pubDate Time.now.strftime('%a, %d %b %Y %H:%M:%S %z')

    @document_list.each do |doc|
      xml.item do
        xml.title feed_item_title(doc)
        xml.description feed_item_content(doc)
        xml.link polymorphic_url(doc)
        xml.guid polymorphic_url(doc)
        xml.pubDate acquired_date(doc).strftime('%a, %d %b %Y %H:%M:%S %z')
      end
      Rails.logger.debug 'jgr25 acquired_dt: ' + nested_hash_value(doc, :acquired_dt) unless nested_hash_value(doc, :acquired_dt).empty?
      Rails.logger.debug 'jgr25 acquired_month: ' + nested_hash_value(doc, :acquired_month) unless nested_hash_value(doc, :acquired_month).empty
    end
  }
}

Rails.logger.level = saved_logger_level
