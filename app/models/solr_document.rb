# froozen_string_literal: true
class SolrDocument

  include Blacklight::Solr::Document
      # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end

  field_semantics.merge!(
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )



  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)
# all of these require MARC format data.
  use_extension( Blacklight::Solr::Document::RIS )
  use_extension( Blacklight::Solr::Document::Zotero )
  use_extension( Blacklight::Solr::Document::Endnote )
  use_extension( Blacklight::Solr::Document::Endnote_xml )

  # i believe that the 520 should be interpreted as ABSTRACT
  # only when indicator1 is "3", but indicator seems to be rarely present.
  def setup_abst_info(record)
    text = []
    record.find_all{|f| f.tag === "520" }.each do |field|
      textstr = ''
      field.each do  |sf|
        textstr << sf.value + ' ' unless ["c", "2","3","6"].include?(sf.code)
      end
      text << textstr
    end
   Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{text[0]}"
   text
  end

  def setup_kw_info(record)
    text = []
    record.find_all{|f| f.tag === "650" }.each do |field|
      textstr = ''
      field.each do  |sf|
        textstr << sf.value + ' ' unless ["0","2","6"].include?(sf.code)
       end unless field.indicator2 == '7'
       text << textstr
    end
    record.find_all{|f| f.tag === "600" }.each do |field|
      textstr = ''
      field.each do  |sf|
        textstr << sf.value + ' ' unless ["0","2","6"].include?(sf.code)
       end if  (field.indicator2 == '0' or field.indicator2 == '1')
       text << textstr
    end
    text
  end

  def setup_notes_info(record)
    text = []
    record.find_all{|f| f.tag === "500" }.each do |field|
      textstr = ''
      field.each do  |sf|
        textstr << sf.value + ' ' unless ["0","2","6"].include?(sf.code)
      end
      text << textstr
    end
    record.find_all{|f| f.tag === "505" }.each do |field|
      text  << field.value
    end
    text
  end

  def setup_isbn_info(record)
    text = []
    record.find_all{|f| f.tag === "020" }.each do |field|
      textstr = ''
      field.each do  |sf|
        textstr << clean_end_punctuation(sf.value) + ' ' if ["a"].include?(sf.code)
      end
      text << textstr
    end
   Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{text[0]}"
    text
  end

  def setup_holdings_info(record)
    where = []
    if (self["holdings_json"].present?)
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} self[h_j] = #{self['holdings_json'].inspect}"
      holdings_json = JSON.parse(self["holdings_json"])
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} holdings_json = #{holdings_json}"
      holdings_keys = holdings_json.keys
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} holdings_keys = #{holdings_keys}"
      where = holdings_keys.collect do
        | k |
        l = holdings_json[k]
        "#{l['location']['library']}  #{l['call']}" unless l.blank? or l['location'].blank? or l['call'].blank?
       end
    end
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} where = #{where.inspect}"
    where
  end 


 

end
