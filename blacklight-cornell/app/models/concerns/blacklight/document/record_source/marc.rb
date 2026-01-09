# frozen_string_literal: true

module Blacklight::Document::RecordSource
  module Marc
    include Base
    include Blacklight::Marc::DocumentExport

    # Build the export title from MARC, honoring separator rules.
    def export_title(separator:)
      if separator == " "
        field = to_marc.find { |f| f.tag == "245" }
        return if field.nil?

        parts = []
        parts << clean_end_punctuation(field["a"].to_s) if field["a"].present?
        parts << clean_end_punctuation(field["b"].to_s) if field["b"].present?
        title = parts.join(" ").strip
        title.presence
      else
        title = setup_title_info(to_marc)
        clean_end_punctuation(title) if title.present?
      end
    end

    # Return contributors parsed from MARC fields.
    def export_contributors
      get_all_authors(to_marc)
    end

    # Return relator roles parsed from MARC fields.
    def export_relators
      get_contrib_roles(to_marc)
    end

    # Compose publication place, publisher, and date values for export.
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

    # Return thesis information when present.
    def export_thesis_info
      data = setup_thesis_info(to_marc)
      data.presence
    end

    # Return edition details when present.
    def export_edition
      setup_edition(to_marc)
    end

    # Return DOI values when present.
    def export_doi
      doi = setup_doi(to_marc)
      doi.presence
    end

    # Return keyword values parsed from MARC.
    def export_keywords
      setup_kw_info(to_marc)
    end

    # Return notes parsed from MARC.
    def export_notes
      setup_notes_info(to_marc)
    end

    # Return abstracts parsed from MARC.
    def export_abstracts
      setup_abst_info(to_marc)
    end

    # Return ISBN values parsed from MARC.
    def export_isbns
      setup_isbn_info(to_marc)
    end

    # Return ISSN values parsed from MARC 022 fields.
    def export_issns
      field = to_marc.find { |f| f.tag == "022" }
      values = []
      return values unless field

      value = field["a"]
      values << clean_end_punctuation(value.to_s) if value.present?
      values
    end

    # Return medium values parsed from MARC.
    def export_medium(kind)
      setup_medium(to_marc, kind)
    end

    apply_export_guard(:marc_record?)
  end
end
