# frozen_string_literal: true
########################################################################################################################
##  Build minimal MARC records from FOLIO docs to allow FOLIO record exports  ##
################################################################################
class FolioMarcAdapter
  def initialize(document)
    @document = document
  end

  def to_marc
    return @marc_record if defined?(@marc_record)
    @marc_record = build_record
  end

  private

  attr_reader :document

  # ===================================
  # Build MARC record from FOLIO record
  # -----------------------------------
  def build_record
    return unless document

    record = MARC::Record.new
    record.leader = '00000nam a2200000   4500'

    append_control_field(record, '001', document['id'])

    has_main_entry = add_authors(record)
    add_title(record, has_main_entry: has_main_entry)
    add_publication(record)

    record
  end

  # ============================================================================
  # 1XX Main Entry (chosen by primary author type)
  #   - 100 1_ $a <personal name>      (Personal Name)
  #   - 110 2_ $a <corporate name>     (Corporate Name)
  #   - 111 2_ $a <meeting name>       (Meeting Name)
  #   - Source: parsed from author_json / author_addl_json "type" where available,
  #             otherwise defaults to Personal Name.
  #   - Purpose: primary access point for the creator/author.
  #
  # 7XX Added Entries (additional authors/contributors)
  #   - 700 1_ $a <personal name>
  #   - 710 2_ $a <corporate name>
  #   - 711 2_ $a <meeting name>
  #   - Source: remaining author entries after the first main entry.
  #
  # Returns boolean: did we add a 1XX main entry?
  # ----------------------------------------------------------------------------
  def add_authors(record)
    entries = author_entries
    return false if entries.empty?

    primary = entries.shift
    append_name_field(record, primary, main: true)

    entries.each do |entry|
      append_name_field(record, entry, main: false)
    end

    true
  end

  # ============================================================================
  # 245 Title Statement
  #   - 245 [ind1][ind2] $a <title proper> $b <remainder/subtitle> $c <statement of responsibility>
  #   - ind1 = '1' if a 1XX field exists in the record, else '0'
  #   - ind2 = '0' (non-filing characters not calculated in this adapter)
  #   - Source: fulltitle_display/title_display; optionally subtitle_display.
  #             Parses ":" into $b and " / " into $c when present.
  # ----------------------------------------------------------------------------
  def add_title(record, has_main_entry:)
    raw_title = first_present_value(%w[fulltitle_display title_display])
    return if raw_title.blank?

    subtitle_from_field = first_present_value(%w[subtitle_display])
    title_parts = parse_title_statement(raw_title, subtitle: subtitle_from_field)

    # If $c is identical to the main author, drop it (it adds little and can look odd)
    if title_parts[:c].present? && primary_name.present?
      if canonical_author_key(title_parts[:c]) == canonical_author_key(primary_name)
        title_parts[:c] = nil
      end
    end

    indicator1 = has_main_entry ? '1' : '0'
    indicator2 = '0'

    subfields = []
    subfields << ['a', title_parts[:a]] if title_parts[:a].present?
    subfields << ['b', title_parts[:b]] if title_parts[:b].present?
    subfields << ['c', title_parts[:c]] if title_parts[:c].present?

    return if subfields.empty?
    record.append(MARC::DataField.new('245', indicator1, indicator2, *subfields))
  end

  # ============================================================================
  # 264 _1 Publication Statement
  #   - 264 _1 $a <place> $b <publisher> $c <year>
  #   - Source: pubplace_display/pub_place_display, publisher_display, pub_date_display,
  #             or parsed pub_info_display fallback.
  # ----------------------------------------------------------------------------
  def add_publication(record)
    pub_data  = publication_data
    subfields = []
    subfields << ['a', pub_data[:place]] if pub_data[:place].present?
    subfields << ['b', pub_data[:publisher]] if pub_data[:publisher].present?
    subfields << ['c', pub_data[:date]] if pub_data[:date].present?
    return if subfields.empty?

    record.append(MARC::DataField.new('264', ' ', '1', *subfields))
  end



  ######################################################################################################################
  ##  Publication parsing helpers ##
  ##################################
  def publication_data
    info      = parsed_pub_info
    place     = first_present_value(%w[pub_place_display pubplace_display]) || info[:place]
    publisher = first_present_value(%w[publisher_display]) || info[:publisher]
    date      = first_present_value(%w[pub_date_display]) || info[:date]
    date      ||= extract_year(document['pub_date_sort'])

    {
      place:     place&.strip,
      publisher: publisher&.strip,
      date:      extract_year(date)
    }
  end

  def parsed_pub_info
    info = first_present_value(%w[pub_info_display])
    return {} if info.blank?

    place       = nil
    publisher   = nil
    date        = nil
    place_split = info.split(':', 2)

    if place_split.length == 2
      place     = place_split[0]
      remainder = place_split[1]
    else
      remainder = place_split[0]
    end

    if remainder
      publisher_split = remainder.split(',', 2)
      publisher       = publisher_split[0]
      date            = publisher_split[1]
    end

    {
      place:     place&.strip,
      publisher: publisher&.strip,
      date:      extract_year(date)
    }
  end

  ######################################################################################################################
  ##  Author parsing + MARC name fields  ##
  #########################################
  # ============================================================================
  # Build typed author entries (name + MARC type) so we can create 100/110/111 etc.
  # Dedupe by canonical key, and prefer the longer display form when dupes exist
  # ----------------------------------------------------------------------------
  def author_entries
    return @author_entries if defined?(@author_entries)

    json_entries = parsed_author_json_entries(%w[author_json author_addl_json])
    explicit_entries =
      field_values(%w[author_display author_addl_display author_facet]).map do |name|
        { name: name, type: nil }
      end

    combined =
      (explicit_entries + json_entries)
        .flatten
        .map do |e|
        name = normalize_author_name(e[:name])
        next if name.blank?
        { name: name, type: (e[:type].presence || nil) }
      end
        .compact

    grouped = combined.group_by { |e| canonical_author_key(e[:name]) }

    @author_entries =
      grouped.values.map do |vals|
        vals.sort_by do |e|
          [
            (e[:type].present? ? 0 : 1), # typed wins
            -e[:name].length             # longer wins
          ]
        end.first
      end

    @author_entries
  end

  # ========================================================================
  # Parse JSON into entries with name + type, rather than dropping type info
  # ------------------------------------------------------------------------
  def parsed_author_json_entries(keys)
    field_values(keys).flat_map do |raw|
      begin
        parsed = JSON.parse(raw)

        case parsed
        when Hash
          type  = parsed['type'] # e.g., "Personal Name", "Corporate Name", "Meeting Name"
          names = [parsed['name1'], parsed['search1'], parsed['name']].compact
          names.map { |n| { name: n, type: type } }
        else
          []
        end
      rescue JSON::ParserError
        []
      end
    end
  end

  # ===========================================================
  # Create correct 1XX/7XX tag + indicator based on author type
  # -----------------------------------------------------------
  def append_name_field(record, entry, main:)
    name = entry[:name]
    return if name.blank?

    tag, ind1 = marc_name_tag_and_ind1(entry[:type], main: main)
    record.append(MARC::DataField.new(tag, ind1, ' ', ['a', name]))
  end


  # ====================================
  # Determine MARC tag/ind1 by name type
  # ------------------------------------
  def marc_name_tag_and_ind1(type, main:)
    normalized = type.to_s.downcase

    if normalized.include?('corporate')
      [main ? '110' : '710', '2']
    elsif normalized.include?('meeting')
      [main ? '111' : '711', '2']
    else
      [main ? '100' : '700', '1']
    end
  end

  def normalize_author_name(name)
    name.to_s
        .strip
        .gsub(/\s+/, ' ')
        .sub(/[[:punct:]]+\z/, '')
  end

  def canonical_author_key(name)
    normalize_author_name(name).downcase
  end

  # ====================================================
  # Expose primary name for title-responsibility cleanup
  # ----------------------------------------------------
  def primary_name
    return @primary_name if defined?(@primary_name)
    @primary_name = author_entries.first&.dig(:name)
  end

  ######################################################################################################################
  ##  Title parsing helpers  ##
  #############################
  # ======================================================================
  # Title splitting into 245 $a/$b/$c.
  # - $c from anything after " / "
  # - $b from remainder after ":" (unless subtitle field already provided)
  # ----------------------------------------------------------------------
  def parse_title_statement(raw, subtitle: nil)
    s = raw.to_s.strip.gsub(/\s+/, ' ')
    return { a: s } if s.blank?

    title_part, resp_part = s.split(/\s+\/\s+/, 2)
    title_part = title_part&.strip
    resp_part  = resp_part&.strip

    a = title_part
    b = subtitle.presence

    if b.blank? && title_part&.include?(':')
      left, right = title_part.split(':', 2)
      a = left.strip
      b = right.strip
    end

    {
      a: a.presence,
      b: b&.strip&.presence,
      c: resp_part&.presence
    }
  end

  ######################################################################################################################
  ##  Generic helpers  ##
  #######################
  def append_control_field(record, tag, value)
    return if value.blank?
    record.append(MARC::ControlField.new(tag, value.to_s))
  end

  def field_values(keys)
    keys.flat_map do |key|
      value = document[key]
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
end
