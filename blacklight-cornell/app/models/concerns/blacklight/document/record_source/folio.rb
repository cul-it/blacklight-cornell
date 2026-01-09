# frozen_string_literal: true

module Blacklight::Document::RecordSource::Folio

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
    folio_title(separator: separator)
  end

  def export_contributors
    authors = author_lists
    personal = (authors[:personal] || []).dup
    corporate = (authors[:corporate] || []).dup
    {
      primary_authors: personal,
      secondary_authors: [],
      primary_corporate_authors: corporate,
      secondary_corporate_authors: [],
      meeting_authors: [],
      editors: [],
      translators: [],
      compilers: []
    }
  end

  def export_relators
    {}
  end

  def export_publication_data
    folio_publication_data
  end

  def export_thesis_info
    nil
  end

  def export_edition
    first_present_value(%w[edition_display])
  end

  def export_languages
    folio_languages
  end

  def export_access_url
    folio_access_url
  end

  def export_catalog_url
    folio_catalog_url
  end

  def export_holdings
    folio_holdings
  end

  def export_holdings_string(separator:)
    folio_holdings_string(separator: separator)
  end

  def export_doi
    first_present_value(%w[doi_display])
  end

  def export_keywords
    folio_keyword_values
  end

  def export_notes
    []
  end

  def export_abstracts
    folio_abstract_values
  end

  def export_isbns
    field_values(%w[isbn_display])
  end

  def export_issns
    field_values(%w[issn_display])
  end

  def export_medium(_kind)
    nil
  end

  private

  ####################################
  ## Shared Helpers ##
  ##################
  def folio_publication_data
    @folio_publication_data ||= publication_data
  end

  def folio_title(separator:)
    title_with_subtitle(separator: separator)
  end

  def folio_languages
    field_values(%w[language_facet])
  end

  def folio_access_url
    access_url_first_filtered(self)
  end

  def folio_catalog_url
    return unless self["id"].present?

    "http://catalog.library.cornell.edu/catalog/#{self['id']}"
  end

  def folio_holdings
    @folio_holdings ||= setup_holdings_info(self)
  end

  def folio_holdings_string(separator:)
    holdings = folio_holdings
    return if holdings.blank? || holdings.join("").blank?

    holdings.join(separator)
  end

  ####################################
  ## Publication/Title/Author Parsing ##
  ##################
  def publication_data
    info = parsed_pub_info
    place = first_present_value(%w[pub_place_display pubplace_display]) || info[:place]
    publisher = first_present_value(%w[publisher_display]) || info[:publisher]
    date = first_present_value(%w[pub_date_display]) || info[:date]
    date ||= extract_year(self["pub_date_sort"])

    {
      place: place&.strip,
      publisher: publisher&.strip,
      date: extract_year(date)
    }
  end

  def parsed_pub_info
    info = first_present_value(%w[pub_info_display])
    return {} if info.blank?

    place = nil
    publisher = nil
    date = nil
    place_split = info.split(":", 2)

    if place_split.length == 2
      place = place_split[0]
      remainder = place_split[1]
    else
      remainder = place_split[0]
    end

    if remainder
      publisher_split = remainder.split(",", 2)
      publisher = publisher_split[0]
      date = publisher_split[1]
    end

    {
      place: place&.strip,
      publisher: publisher&.strip,
      date: extract_year(date)
    }
  end

  def author_lists
    return @author_lists if defined?(@author_lists)

    json_entries = parsed_author_json_entries(%w[author_json author_addl_json])
    explicit_entries =
      field_values(%w[author_display author_addl_display author_facet]).map do |name|
        { name: name, type: nil }
      end

    combined =
      (explicit_entries + json_entries)
        .flatten
        .map do |entry|
        name = normalize_author_name(entry[:name])
        next if name.blank?
        { name: name, type: (entry[:type].presence || nil) }
      end
        .compact

    grouped = combined.group_by { |entry| canonical_author_key(entry[:name]) }

    entries =
      grouped.values.map do |values|
        values.sort_by do |entry|
          [
            (entry[:type].present? ? 0 : 1),
            -entry[:name].length
          ]
        end.first
      end

    personal = []
    corporate = []
    meeting = []
    entries.each do |entry|
      normalized = entry[:type].to_s.downcase
      if normalized.include?("corporate")
        corporate << entry[:name]
      elsif normalized.include?("meeting")
        meeting << entry[:name]
      else
        personal << entry[:name]
      end
    end

    corporate += meeting

    @author_lists = { personal: personal, corporate: corporate }
  end

  def parsed_author_json_entries(keys)
    field_values(keys).flat_map do |raw|
      begin
        parsed = JSON.parse(raw)

        case parsed
        when Hash
          type = parsed["type"]
          names = [parsed["name1"], parsed["search1"], parsed["name"]].compact
          names.map { |name| { name: name, type: type } }
        else
          []
        end
      rescue JSON::ParserError
        []
      end
    end
  end

  def normalize_author_name(name)
    name.to_s.strip.gsub(/\s+/, " ").sub(/[[:punct:]]+\z/, "")
  end

  def canonical_author_key(name)
    normalize_author_name(name).downcase
  end

  def title_with_subtitle(separator:)
    raw_title = first_present_value(%w[fulltitle_display title_display])
    return nil if raw_title.blank?

    subtitle_from_field = first_present_value(%w[subtitle_display])
    title_part = raw_title.to_s.strip.gsub(/\s+/, " ")
    title_part = title_part.split(/\s+\/\s+/, 2).first&.strip

    title = title_part
    subtitle = subtitle_from_field

    if subtitle.blank? && title_part&.include?(":")
      left, right = title_part.split(":", 2)
      title = left.strip
      subtitle = right.strip
    end

    title = clean_end_punctuation(title)
    subtitle = clean_end_punctuation(subtitle)

    if subtitle.present?
      [title, subtitle].compact.join(separator)
    else
      title
    end
  end

  def field_values(keys)
    keys.flat_map do |key|
      value = self[key]
      value.is_a?(Array) ? value : [value]
    end.flatten.compact
  end

  def first_present_value(keys)
    field_values(keys).find { |value| value.present? }
  end

  def extract_year(value)
    return if value.blank?
    value.to_s.scan(/\d{4}/).first
  end

  def clean_end_punctuation(text)
    return "" if text.nil?
    if [".", ",", ":", ";", "/"].include?(text[-1, 1])
      return text[0, text.length - 1]
    end
    text
  end

  ####################################
  ## Keyword/Abstract Helpers ##
  ##################
  def folio_keyword_values
    values = field_values(%w[keyword_display])
    field_values(%w[subject_json]).each do |raw|
      begin
        parsed = JSON.parse(raw)
        case parsed
        when Array
          parsed.each do |entry|
            if entry.is_a?(Hash)
              values << entry["subject"]
            else
              values << entry
            end
          end
        when Hash
          values << parsed["subject"]
        else
          values << parsed
        end
      rescue JSON::ParserError
        next
      end
    end

    values.compact.map { |value| strip_html(value.to_s).strip }.reject(&:blank?).uniq
  end

  def folio_abstract_values
    field_values(%w[summary_display description_display])
      .map { |value| strip_html(value.to_s).strip }
      .reject(&:blank?)
  end

  def strip_html(text)
    text.gsub(/<[^>]*>/, "")
  end

  apply_export_guard(:folio_record?)
end
