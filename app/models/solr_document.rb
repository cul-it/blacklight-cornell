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
  use_extension( Blacklight::Solr::Document::RIS )
  use_extension( Blacklight::Solr::Document::Zotero )

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
        textstr << sf.value + ' ' if ["a"].include?(sf.code)
      end
      text << textstr
    end
   Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{text[0]}"
    text
  end

  def setup_holdings_info(record)
    holdings_arr = self["holdings_record_display"]
    holdings = []
    where_arr = holdings_arr.collect { | h |  JSON.parse(h).with_indifferent_access }
    where = where_arr.collect { | h |  "#{h['locations'][0]['library']}  #{h['callnos'][0]}" unless h.blank? or h['locations'].blank? or     h['callnos'].blank?}
    where
  end 


 

end
