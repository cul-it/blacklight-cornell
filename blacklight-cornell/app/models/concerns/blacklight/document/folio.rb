# frozen_string_literal: true

module Blacklight::Document::Folio
  def export_ris
    return nil unless folio_record?

    ty = ris_type_for_format(folio_format)
    output = +"TY  - #{ty}\n"

    title = title_with_subtitle(separator: ": ")
    output << "TI  - #{title}\n" if title.present?

    authors = author_lists
    primary_authors = authors[:personal].presence || authors[:corporate]
    if primary_authors.present?
      output << "AU  - #{primary_authors[0]}\n"
      primary_authors.drop(1).each_with_index do |author, index|
        output << "A#{index + 1}  - #{author}\n"
      end
    end

    pub_data = publication_data
    output << "PY  - #{pub_data[:date]}\n" if pub_data[:date].present?
    output << "PB  - #{pub_data[:publisher]}\n" if pub_data[:publisher].present?
    output << "CY  - #{pub_data[:place]}\n" if pub_data[:place].present?

    if self["language_facet"].present?
      self["language_facet"].each { |lang| output << "LA  - #{lang}\n" }
    end

    access_url = access_url_first_filtered(self)
    output << "UR  - #{access_url}\n" if access_url.present?

    if self["id"].present?
      output << "M2  - http://catalog.library.cornell.edu/catalog/#{self['id']}\n"
      output << "N1  - http://catalog.library.cornell.edu/catalog/#{self['id']}\n"
    end

    holdings = setup_holdings_info(self)
    output << "CN  - #{holdings.join(' ')}\n" unless holdings.join("").blank?

    output << "ER  - \n"

    output
  end

  def export_as_endnote
    return nil unless folio_record?

    fmt_str = endnote_type_for_format(folio_format)
    text = +"%0 #{fmt_str}\n"

    if self["language_facet"].present?
      self["language_facet"].each { |lang| text << "%G #{lang}\n" }
    end

    title = title_with_subtitle(separator: " ")
    text << "%T #{title}\n" if title.present?

    authors = author_lists
    author_list = authors[:personal]
    if author_list.present?
      text << "%A #{author_list[0]}\n"
      author_list.drop(1).each { |author| text << "%E #{author}\n" }
    end

    pub_data = publication_data
    text << "%I #{pub_data[:publisher]}\n" if pub_data[:publisher].present?
    text << "%C #{pub_data[:place]}\n" if pub_data[:place].present?
    text << "%D #{pub_data[:date]}\n" if pub_data[:date].present?

    holdings = setup_holdings_info(self)
    text << "%L #{holdings.join(' ')}\n" unless holdings.join("").blank?
    text << "%Z http://catalog.library.cornell.edu/catalog/#{self['id']}\n" if self["id"].present?

    text
  end

  def export_as_endnote_xml
    return nil unless folio_record?

    fmt = folio_format
    ty = endnote_type_for_format(fmt)
    num_ty = endnote_numeric_type(ty)

    title = title_with_subtitle(separator: ": ")
    pub_data = publication_data
    authors = author_lists
    author_list = authors[:personal].presence || authors[:corporate]

    builder = Builder::XmlMarkup.new(:indent => 2, :margin => 4)
    builder.tag!("xml") do
      builder.records do
        builder.record do
          builder.database("MyLibrary")
          builder.tag!("source-app", "Cornell University Library", "name" => "CULIB")
          builder.tag!("ref-type", num_ty, "name" => ty)
          builder.contributors do
            if author_list.present?
              builder.authors do
                author_list.each { |author| builder.author(author) }
              end
            end
          end
          builder.titles do
            builder.title(title) if title.present?
          end
          if pub_data[:date].present?
            builder.dates do
              builder.year(pub_data[:date])
              builder.tag!("pub-dates") { builder.date(pub_data[:date]) }
            end
          end
          builder.tag!("pub-location", pub_data[:place]) if pub_data[:place].present?
          builder.publisher(pub_data[:publisher]) if pub_data[:publisher].present?
          holdings = setup_holdings_info(self)
          builder.tag!("call-num", holdings.join(" ")) unless holdings.join("").blank?
          if self["id"].present?
            builder.notes("http://catalog.library.cornell.edu/catalog/#{self['id']}\n")
          end
          if self["language_facet"].present?
            self["language_facet"].each { |lang| builder.language(lang) }
          end
        end
      end
    end

    builder.target!
  end

  private

  def folio_format
    value = self["format"]
    value.is_a?(Array) ? value.first : value
  end

  def ris_type_for_format(fmt)
    type = Blacklight::Document::Ris::FACET_TO_RIS_TYPE[fmt] || "GEN"
    if fmt == "Book" && self["online"] && self["online"].first == "Online"
      type = "EBOOK"
    end
    type
  end

  def endnote_type_for_format(fmt)
    type = Blacklight::Document::Endnote::FACET_TO_ENDNOTE_TYPE[fmt] || "Generic"
    if fmt == "Book" && self["online"] && self["online"].first == "Online"
      type = "Electronic Book"
    end
    type
  end

  def endnote_numeric_type(type)
    Blacklight::Document::EndnoteXml::FACET_TO_ENDNOTE_NUMERIC_VALUE[type] || "0"
  end

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
end
