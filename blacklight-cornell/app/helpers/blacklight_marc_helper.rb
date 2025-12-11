module BlacklightMarcHelper
  def render_endnote_xml_texts(documents)
    val = ''
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__}"
    documents.each do |doc|
      tmp = ''
      if doc.exports_as?(:endnote_xml) && doc.exportable_marc_record?
        tmp = doc.export_as(:endnote_xml) + "\n"
        tmp.sub!('<xml>','')
        tmp.sub!('</xml>','')
        tmp.sub!('<records>','')
        tmp.sub!('</records>','')
        val += tmp
      end
    end
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__} val = #{val}"
   "<xml><records> #{val} </records></xml>"
  end

  # puts together a collection of documents into one ris export string
  def render_ris_texts(documents)
    val = ''
    Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__}"
    documents.each do |doc|
      if doc.exports_as?(:ris) && doc.exportable_marc_record?
        val += doc.export_as(:ris) + "\n"
      end
    end
    val
  end
end
