# frozen_string_literal: true

module Blacklight::Document::RecordSource::Marc
  include Blacklight::Marc::DocumentExport

  def self.apply_export_guard(record_source)
    guard_key = record_source.to_s.gsub(/\W/, "_")
    instance_methods(false).grep(/\Aexport_/).each do |name|
      guarded = "__#{guard_key}_#{name}"
      next if method_defined?(guarded)
      alias_method guarded, name
      define_method(name) do |*args, **kwargs, &block|
        return super(*args, **kwargs, &block) unless public_send(record_source)
        send(guarded, *args, **kwargs, &block)
      end
    end
  end

  def export_format
    value = self["format"]
    value.is_a?(Array) ? value.first : value
  end

  def export_online?
    online = self["online"]
    online.is_a?(Array) ? online.first == "Online" : online == "Online"
  end

  def export_title(separator:)
    if separator == " "
      export_title_with_space
    else
      title = setup_title_info(to_marc)
      clean_end_punctuation(title) if title.present?
    end
  end

  def export_contributors
    get_all_authors(to_marc)
  end

  def export_relators
    get_contrib_roles(to_marc)
  end

  def export_publication_data
    pub_data = setup_pub_info(to_marc)
    place = nil
    publisher = nil
    if pub_data.present?
      place, publisher = pub_data.split(":", 2)
    end

    {
      place: place&.strip,
      publisher: publisher&.strip,
      date: setup_pub_date(to_marc)
    }
  end

  def export_thesis_info
    data = setup_thesis_info(to_marc)
    data.presence
  end

  def export_edition
    setup_edition(to_marc)
  end

  def export_languages
    export_field_values(%w[language_facet])
  end

  def export_access_url
    access_url_first_filtered(self)
  end

  def export_catalog_url
    return unless self["id"].present?

    "http://catalog.library.cornell.edu/catalog/#{self['id']}"
  end

  def export_holdings
    setup_holdings_info(self)
  end

  def export_holdings_string(separator:)
    holdings = export_holdings
    return if holdings.blank? || holdings.join("").blank?

    holdings.join(separator)
  end

  def export_doi
    doi = setup_doi(to_marc)
    doi.presence
  end

  def export_keywords
    setup_kw_info(to_marc)
  end

  def export_notes
    setup_notes_info(to_marc)
  end

  def export_abstracts
    setup_abst_info(to_marc)
  end

  def export_isbns
    setup_isbn_info(to_marc)
  end

  def export_issns
    field = to_marc.find { |f| f.tag == "022" }
    values = []
    return values unless field

    value = field["a"]
    values << clean_end_punctuation(value.to_s) if value.present?
    values
  end

  def export_medium(kind)
    setup_medium(to_marc, kind)
  end

  private

  def export_title_with_space
    field = to_marc.find { |f| f.tag == "245" }
    return if field.nil?

    parts = []
    parts << clean_end_punctuation(field["a"].to_s) if field["a"].present?
    parts << clean_end_punctuation(field["b"].to_s) if field["b"].present?
    title = parts.join(" ").strip
    title.presence
  end

  def export_field_values(keys)
    keys.flat_map do |key|
      value = self[key]
      value.is_a?(Array) ? value : [value]
    end.flatten.compact
  end

  apply_export_guard(:marc_record?)
end
