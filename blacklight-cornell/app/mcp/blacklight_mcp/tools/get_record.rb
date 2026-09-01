# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # Everything stored for one record, for when the search summary isn't enough.
    class GetRecord < Base
      tool_name 'get_record'
      read_only 'Fetch one catalog record'

      description <<~TEXT
        Fetch the complete catalog record for one id, as returned by `search` or
        `advanced_search` in each document's "id" field.

        By default this returns the summary fields plus every stored Solr field, which
        is verbose. Pass fields to pull back only the ones you need.
      TEXT

      input_schema(
        properties: {
          id: { type: 'string', minLength: 1, description: 'The catalog record id, e.g. "9876543".' },
          fields: {
            type: 'array',
            items: { type: 'string' },
            description: 'Restrict the full record to these Solr field names. Omit for everything.'
          }
        },
        required: %w[id],
        additionalProperties: false
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          id = args[:id].to_s.strip
          raise InvalidArgument, 'id is required' if id.blank?

          document = SearchRunner.new({}).document(id)
          payload = ResultPresenter.document(document, base_url: base_url(server_context))
          payload['record'] = record_fields(document, args[:fields])
          respond(payload)
        end
      end

      def self.record_fields(document, fields)
        source = document.to_h.deep_stringify_keys
        return source if fields.blank?

        source.slice(*Array(fields).map(&:to_s))
      end
    end
  end
end
