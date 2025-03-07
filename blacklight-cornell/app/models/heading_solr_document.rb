class HeadingSolrDocument
  include Blacklight::Solr::Document

  def type
    type_for_desc(fetch('headingTypeDesc', ''))
  end

  def type_for_desc(heading_type_desc)
    case heading_type_desc
    when 'Personal Name'
      'pers'
    when 'Corporate Name'
      'corp'
    when 'Event'
      'event'
    when 'Geographic Name'
      'geo'
    when 'Chronological Term'
      'era'
    when 'Genre/Form Term'
      'genr'
    when 'Topical Term'
      'topic'
    else
      # No headingTypeDesc for authortitle headings
      'work'
    end
  end

  def browse_fields
    return [] unless type.present?

    browse_fields = ["subject_#{type}_browse"]
    if ['pers', 'corp', 'event'].include?(type)
      browse_fields << "author_#{type}_browse"
    elsif type == 'work'
      browse_fields << 'authortitle_browse'
    end
    browse_fields
  end
end
