# frozen_string_literal: true

module Blacklight::Document::RecordSource::Folio
  ######################################################################################################################
  ##  RIS Format  ##
  ##################
  def export_ris
    return super unless folio_record?

    ty = ris_type_for_format(folio_format)
    output = +"TY  - #{ty}\n"

    append_tagged_value(output, "TI  -", folio_title(separator: ": "))
    append_ris_authors(output)
    append_ris_publication_data(output, folio_publication_data)
    append_tagged_values(output, "LA  -", folio_languages)
    append_tagged_value(output, "UR  -", folio_access_url)

    catalog_url = folio_catalog_url
    if catalog_url.present?
      output << "M2  - #{catalog_url}\n"
      output << "N1  - #{catalog_url}\n"
    end

    append_tagged_value(output, "CN  -", folio_holdings_string(separator: " "))

    output << "ER  - \n"
    output
  end

  ######################################################################################################################
  ##  Endnote Format  ##
  ######################
  def export_as_endnote
    return super unless folio_record?

    fmt_str = endnote_type_for_format(folio_format)
    text = +"%0 #{fmt_str}\n"

    append_tagged_values(text, "%G", folio_languages)
    append_tagged_value(text, "%T", folio_title(separator: " "))
    append_endnote_authors(text)
    append_endnote_publication_data(text, folio_publication_data)
    append_tagged_value(text, "%L", folio_holdings_string(separator: " "))
    append_tagged_value(text, "%Z", folio_catalog_url)

    text
  end

  ######################################################################################################################
  ##  Endnote XML Format  ##
  ##########################
  def export_as_endnote_xml
    return super unless folio_record?

    fmt = folio_format
    ty = endnote_type_for_format(fmt)
    num_ty = endnote_numeric_type(ty)

    title = folio_title(separator: ": ")
    pub_data = folio_publication_data
    author_list = folio_primary_authors

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
          holdings = folio_holdings_string(separator: " ")
          builder.tag!("call-num", holdings) if holdings.present?
          catalog_url = folio_catalog_url
          builder.notes("#{catalog_url}\n") if catalog_url.present?
          folio_languages.each { |lang| builder.language(lang) }
        end
      end
    end

    builder.target!
  end

  ######################################################################################################################
  ##  Zotero RDF Format  ##
  #########################
  def generate_rdf_zotero
    return super unless folio_record?

    fmt = folio_format
    ty = Blacklight::Document::Zotero::FACET_TO_ZOTERO_TYPE[fmt] || "book"
    tag = case ty
    when "videoRecording", "audioRecording"
      "Recording"
    when "map"
      "Image"
    else
      "Book"
    end

    title = folio_title(separator: ": ")

    builder = Builder::XmlMarkup.new(:indent => 2, :margin => 4)
    builder.tag!("rdf:RDF",
                 "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                 "xmlns:z" => "http://www.zotero.org/namespaces/export#",
                 "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
                 "xmlns:vcard" => "http://nwalsh.com/rdf/vCard#",
                 "xmlns:foaf" => "http://xmlns.com/foaf/0.1/",
                 "xmlns:bib" => "http://purl.org/net/biblio#",
                 "xmlns:prism" => "http://prismstandard.org/namespaces/1.2/basic/",
                 "xmlns:dcterms" => "http://purl.org/dc/terms/") do
      builder.bib(tag.to_sym) do
        builder.z(:itemType, ty)
        builder.dc(:title, title.strip) if title.present?
        generate_folio_zotero_authors(builder, ty)
        generate_folio_zotero_publisher(builder)
        generate_folio_zotero_pubdate(builder)
        generate_folio_zotero_language(builder)
        generate_folio_zotero_keywords(builder)
        generate_folio_zotero_abstract(builder)
        generate_folio_zotero_url(builder)
        generate_folio_zotero_holdings(builder)
        generate_folio_zotero_catalog_link(builder)
      end
    end

    builder.target!
  end


  private
  ######################################################################################################################
  ##  Helper Methods  ##
  ######################

  #####################---------------------------------------------------------
  ##  Shared Methods ##
  #####################
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

  def folio_primary_authors
    authors = author_lists
    authors[:personal].presence || authors[:corporate]
  end

  def folio_personal_authors
    author_lists[:personal]
  end

  def append_tagged_value(buffer, prefix, value)
    buffer << "#{prefix} #{value}\n" if value.present?
  end

  def append_tagged_values(buffer, prefix, values)
    values.each { |value| append_tagged_value(buffer, prefix, value) }
  end


  ###################-----------------------------------------------------------
  ##  RIS Helpers  ##
  ###################
  def append_ris_authors(buffer)
    authors = folio_primary_authors
    return if authors.blank?

    buffer << "AU  - #{authors[0]}\n"
    authors.drop(1).each_with_index do |author, index|
      buffer << "A#{index + 1}  - #{author}\n"
    end
  end


  #######################-------------------------------------------------------
  ##  Endnote Helpers  ##
  #######################
  def append_endnote_authors(buffer)
    authors = folio_personal_authors
    return if authors.blank?

    buffer << "%A #{authors[0]}\n"
    authors.drop(1).each { |author| buffer << "%E #{author}\n" }
  end

  def append_ris_publication_data(buffer, pub_data)
    append_tagged_value(buffer, "PY  -", pub_data[:date])
    append_tagged_value(buffer, "PB  -", pub_data[:publisher])
    append_tagged_value(buffer, "CY  -", pub_data[:place])
  end

  def append_endnote_publication_data(buffer, pub_data)
    append_tagged_value(buffer, "%I", pub_data[:publisher])
    append_tagged_value(buffer, "%C", pub_data[:place])
    append_tagged_value(buffer, "%D", pub_data[:date])
  end


  ######################--------------------------------------------------------
  ##  Zotero Helpers  ##
  ######################
  def generate_folio_zotero_authors(builder, ty)
    author_list = folio_primary_authors
    return if author_list.blank?

    auty = case ty
    when "videoRecording"
      "contributors"
    when "audioRecording"
      "performers"
    when "map"
      "cartographers"
    else
      "authors"
    end
    ns = %w[contributors authors editors].include?(auty) ? "bib" : "z"

    builder.tag!("#{ns}:#{auty}") do
      builder.rdf(:Seq) do
        author_list.each { |author| builder.rdf(:li) { generate_folio_zotero_person(builder, author) } }
      end
    end
  end

  def generate_folio_zotero_person(builder, name)
    surname = name
    surname, givenname = name.split(",", 2) if name.include?(",")
    builder.foaf(:Person) do
      sn = surname.to_s.strip
      builder.foaf(:surname, sn) unless sn.blank?
      gn = givenname.to_s.strip
      builder.foaf(:givenname, gn) unless gn.blank?
    end
  end

  def generate_folio_zotero_publisher(builder)
    pub_data = folio_publication_data
    return if pub_data[:place].blank? && pub_data[:publisher].blank?

    builder.dc(:publisher) do
      builder.foaf(:Organization) do
        builder.vcard(:adr) do
          builder.vcard(:Address) do
            builder.vcard(:locality, pub_data[:place]) if pub_data[:place].present?
          end
        end
        builder.foaf(:name, pub_data[:publisher]) if pub_data[:publisher].present?
      end
    end
  end

  def generate_folio_zotero_pubdate(builder)
    pub_data = folio_publication_data
    builder.dc(:date, pub_data[:date]) if pub_data[:date].present?
  end

  def generate_folio_zotero_language(builder)
    folio_languages.each { |lang| builder.z(:language, lang) }
  end

  def generate_folio_zotero_keywords(builder)
    folio_keyword_values.each { |keyword| builder.dc(:subject, keyword) }
  end

  def generate_folio_zotero_abstract(builder)
    abstracts = folio_abstract_values
    return if abstracts.blank?

    builder.dcterms(:abstract, abstracts.join(" "))
  end

  def generate_folio_zotero_url(builder)
    access_url = folio_access_url
    return if access_url.blank?

    builder.dc(:identifier) { builder.dcterms(:URI) { builder.rdf(:value, access_url) } }
  end

  def generate_folio_zotero_holdings(builder)
    holdings = folio_holdings_string(separator: "//")
    return if holdings.blank?

    builder.dc(:subject) { builder.dcterms(:LCC) { builder.rdf(:value, holdings) } }
  end

  def generate_folio_zotero_catalog_link(builder)
    catalog_url = folio_catalog_url
    return if catalog_url.blank?

    builder.dc(:description, catalog_url)
  end

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


  ########################################--------------------------------------
  ##  Publication/Title/Author Parsing  ##
  ########################################
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
