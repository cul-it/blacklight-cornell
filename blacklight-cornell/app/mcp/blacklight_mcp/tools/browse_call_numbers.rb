# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # What is shelved either side of a call number -- the thing a reader does by
    # walking to the shelf and looking left and right, which is often how the
    # useful book gets found.
    class BrowseCallNumbers < Base
      tool_name 'browse_call_numbers'
      read_only 'Browse the shelf around a call number'

      description <<~TEXT
        List what sits at and after a call number in shelf order, or before it. This is
        the shelf browse a reader does in person, and it finds books a subject search
        misses because they were catalogued under different words.

        Pass the call number EXACTLY as it appears on the record, including any leading
        location words such as "Willis Room GV1469.F67 L43 2010" or "Asia Rare GV1469.G7
        G32 +". This index is ordered by the whole string, so dropping those words does
        not tidy the input -- it starts you somewhere else entirely on the shelf. A
        partial call number is fine ("GV1469") as long as you do not remove anything
        from the front.

        The reply has two views of the same rows. "table" is them already laid out --
        call number linking to the record, then citation, format, library and status,
        the columns the catalog's own browse page shows. Show that table as it stands,
        so every call number lookup comes out looking the same. "entries" is the same
        data as fields, including an "id" for get_record, fetch or check_availability.

        One entry per item, not per title, so a book held in several libraries appears
        several times. Call numbers next to each other are not always shelves next to
        each other: an item can be off-site or in another library.
      TEXT

      input_schema(
        properties: {
          call_number: {
            type: 'string',
            minLength: 1,
            description: 'Where to start, copied exactly from the record -- keep any leading ' \
                         'location words like "Willis Room" or "Asia Rare", which are part of ' \
                         'the string this index is ordered by. Removing them starts you ' \
                         'somewhere else on the shelf. A partial call number is fine ("GV1469").'
          },
          direction: {
            type: 'string',
            enum: CallNumberBrowse::DIRECTIONS,
            description: 'forward for what is at and after this call number (default), ' \
                         'backward for what comes before it.'
          },
          limit: {
            type: 'integer',
            minimum: 1,
            maximum: CallNumberBrowse::MAX_LIMIT,
            description: "How many entries (default #{CallNumberBrowse::DEFAULT_LIMIT}, " \
                         "max #{CallNumberBrowse::MAX_LIMIT})."
          }
        },
        required: %w[call_number],
        additionalProperties: false
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          direction = validated_direction(args[:direction])
          limit = validated_limit(args[:limit])

          entries = CallNumberBrowse.entries(call_number: args[:call_number],
                                             direction: direction,
                                             limit: limit)

          respond(payload(args[:call_number], direction, entries, base_url(server_context)))
        end
      end

      def self.validated_direction(value)
        return CallNumberBrowse::FORWARD if value.blank?

        direction = value.to_s.strip.downcase
        unless CallNumberBrowse::DIRECTIONS.include?(direction)
          raise InvalidArgument,
                "direction must be one of: #{CallNumberBrowse::DIRECTIONS.join(', ')} (got #{value.inspect})"
        end

        direction
      end

      def self.validated_limit(value)
        return CallNumberBrowse::DEFAULT_LIMIT if value.blank?

        limit = Integer(value.to_s.strip)
        unless limit.between?(1, CallNumberBrowse::MAX_LIMIT)
          raise InvalidArgument, "limit must be between 1 and #{CallNumberBrowse::MAX_LIMIT} (got #{limit})"
        end

        limit
      rescue ArgumentError, TypeError
        raise InvalidArgument, "limit must be a whole number (got #{value.inspect})"
      end

      def self.payload(call_number, direction, entries, base_url)
        rows = entries.map { |entry| with_url(entry, base_url) }

        {
          'call_number' => call_number.to_s.strip,
          'direction' => direction,
          # The rows already laid out, so every call number lookup comes back
          # looking the same instead of being rebuilt differently each time.
          # `entries` is the same data structured, for chaining into other tools.
          'table' => table(rows),
          'entries' => rows
        }
      end

      COLUMNS = ['Call number', 'Citation', 'Format', 'Library', 'Status'].freeze

      # The columns the catalog's own call number browse page shows, with the
      # call number linking to the record.
      def self.table(rows)
        return 'No items at or after this call number.' if rows.empty?

        ([
          "| #{COLUMNS.join(' | ')} |",
          "| #{COLUMNS.map { '---' }.join(' | ')} |"
        ] + rows.map { |row| table_row(row) }).join("\n")
      end

      def self.table_row(row)
        call_number = cell(row['call_number'] || '—')
        link = row['url'] || row['path']
        first = link.present? ? "[#{call_number}](#{link})" : call_number

        "| #{first} | #{cell(row['citation'])} | #{cell(row['format'])} | " \
          "#{cell(row['library'])} | #{cell(row['status'])} |"
      end

      # A pipe inside a citation would otherwise split the row into a new column.
      def self.cell(value)
        value.to_s.gsub('|', '\\|').presence || '—'
      end

      def self.with_url(entry, base_url)
        return entry if base_url.blank? || entry['path'].blank?

        entry.merge('url' => "#{base_url}#{entry['path']}")
      end
    end
  end
end
