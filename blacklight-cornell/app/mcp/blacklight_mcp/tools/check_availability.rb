# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # "Can I get this book right now, and where do I go?" -- the question a
    # student actually has once a search has found something.
    class CheckAvailability < Base
      tool_name 'check_availability'
      read_only 'Check whether records are available now'

      # Several ids at once, because the question is almost never about one
      # record: a student has a list of five candidates and wants the one they
      # can pick up today. Each id costs nothing extra -- they are fetched in a
      # single Solr round trip.
      MAX_IDS = 10

      description <<~TEXT
        Check whether specific catalog records are available right now: online access
        links, which library holds a physical copy, its call number, and how many of
        its items are on the shelf rather than checked out.

        Pass the "id" values from `search`, `advanced_search` or `get_record`. Ids that
        don't exist come back in "not_found" rather than failing the whole call.

        Availability here is what the catalog last indexed, so it can lag a checkout by
        a short while. For borrowing, recalls and holds, send the reader to the record
        page in "url" -- this tool never places a request.
      TEXT

      input_schema(
        properties: {
          ids: {
            type: 'array',
            items: { type: 'string', minLength: 1 },
            minItems: 1,
            maxItems: MAX_IDS,
            description: "Catalog record ids, e.g. [\"9876543\"]. At most #{MAX_IDS} per call."
          }
        },
        required: %w[ids],
        additionalProperties: false
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          ids = clean_ids(args[:ids])
          documents = SearchRunner.new({}).documents(ids)
          respond(payload(ids, documents, base_url(server_context)))
        end
      end

      def self.clean_ids(value)
        raise InvalidArgument, 'ids must be an array of catalog record ids' unless value.is_a?(Array)

        ids = value.map { |id| id.to_s.strip }.reject(&:blank?).uniq
        raise InvalidArgument, 'ids must contain at least one catalog record id' if ids.empty?

        if ids.size > MAX_IDS
          raise InvalidArgument, "ids accepts at most #{MAX_IDS} ids per call (got #{ids.size}). " \
                                 'Split the list across calls.'
        end

        ids
      end

      # Solr returns what it has, in its own order. Reporting the misses by name
      # keeps a typo in one id from looking like an availability answer.
      def self.payload(ids, documents, base_url)
        found = documents.index_by { |document| document.id.to_s }

        {
          'records' => ids.filter_map do |id|
            document = found[id]
            AvailabilityPresenter.new(document, base_url: base_url).to_h if document
          end,
          'not_found' => ids.reject { |id| found.key?(id) }
        }.reject { |_key, value| value.blank? }
      end
    end
  end
end
