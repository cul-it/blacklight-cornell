# frozen_string_literal: true

########################################################################################################################
##                  FOLIO Record Source                           ##
## -------------------------------------------------------------- ##
##    Maps FOLIO source records from Solr Document to Exports     ##
####################################################################
module Blacklight::Document::Source
  module Folio
    include Base

    # Build the export title from Solr title and subtitle fields.
    def export_title(separator:)
      title_with_subtitle(separator: separator)
    end

    # Return contributors grouped into the export hash shape.
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

    # Folio records do not include relator data for exports.
    def export_relators
      {}
    end

    # Compose publication place, publisher, and date values for export.
    def export_publication_data
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

    # Folio records do not expose thesis information.
    def export_thesis_info
      nil
    end

    # Pull the edition from display fields when present.
    def export_edition
      first_present_value(%w[edition_display])
    end

    # Pull DOI values from display fields when present.
    def export_doi
      first_present_value(%w[doi_display])
    end

    # Gather keyword values from display and JSON fields.
    def export_keywords
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

    # Folio records do not provide export notes.
    def export_notes
      []
    end

    # Gather abstract values from display fields.
    def export_abstracts
      field_values(%w[summary_display description_display]).map { |value| strip_html(value.to_s).strip }.reject(&:blank?)
    end

    # Return ISBNs from display fields.
    def export_isbns
      field_values(%w[isbn_display])
    end

    # Return ISSNs from display fields.
    def export_issns
      field_values(%w[issn_display])
    end

    # Folio exports do not provide medium values.
    def export_medium(_kind)
      nil
    end

    private
    # Parse place, publisher, and date from the pub_info display string.
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

    # Build normalized author lists from JSON and display fields.
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

      grouped = combined.group_by { |entry| normalize_author_name(entry[:name]).downcase }

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

    # Extract author entries from JSON fields, ignoring parse errors.
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

    # Normalize author names for comparisons and display.
    def normalize_author_name(name)
      name.to_s.strip.gsub(/\s+/, " ").sub(/[[:punct:]]+\z/, "")
    end

    # Assemble a title with an optional subtitle using Solr fields.
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

    # Extract a 4-digit year from a value.
    def extract_year(value)
      return if value.blank?

      value.to_s.scan(/\d{4}/).first
    end

    # Strip HTML tags from display values.
    def strip_html(text)
      text.gsub(/<[^>]*>/, "")
    end
  end
end