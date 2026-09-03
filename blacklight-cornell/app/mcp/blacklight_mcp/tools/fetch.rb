# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # One record as readable text.
    #
    # Named `fetch` because ChatGPT's deep research connectors look for a tool by
    # that exact name, paired with `search`, and expect it to return
    # id / title / text / url / metadata. It is useful to any assistant, though:
    # `get_record` hands back every stored field, which is a lot to read, while
    # this is the same record written out as prose.
    class Fetch < Base
      tool_name 'fetch'
      read_only 'Fetch one record as readable text'

      description <<~TEXT
        Fetch one catalog record as readable text, using an "id" from `search` or
        `advanced_search`.

        Returns the record's title, a plain-text description of it, a link to it in
        the catalog, and its main fields separately as metadata. Use `get_record`
        instead when you need every stored field, including raw MARC.
      TEXT

      input_schema(
        properties: {
          id: { type: 'string', minLength: 1, description: 'The catalog record id, e.g. "12275844".' }
        },
        required: %w[id],
        additionalProperties: false
      )

      # Each line of the text body: a label, and the fields to read it from. The
      # first field that has a value wins.
      TEXT_FIELDS = {
        'Author' => %w[author_display author_vern_display],
        'Format' => %w[format],
        'Published' => %w[pub_info_display],
        'Edition' => %w[edition_display],
        'Series' => %w[title_series_display],
        'Language' => %w[language_display],
        'Description' => %w[description_display],
        'Call number' => %w[lc_callnum_display callnumber_display],
        'ISBN' => %w[isbn_display],
        'Subjects' => %w[subject_display],
        'Contents' => %w[contents_display],
        'Notes' => %w[notes_display]
      }.freeze

      # Long fields like a table of contents can run to thousands of words, which
      # is more than an assistant needs to judge relevance.
      MAX_FIELD_LENGTH = 2_000

      def self.call(server_context: nil, **args)
        handling_errors do
          id = args[:id].to_s.strip
          raise InvalidArgument, 'id is required' if id.blank?

          document = SearchRunner.new({}).document(id)
          summary = ResultPresenter.document(document, base_url: base_url(server_context))

          respond(
            'id' => summary['id'],
            'title' => summary['title'].to_s,
            'text' => text_for(document, summary),
            'url' => summary['url'] || summary['path'],
            'metadata' => summary.except('id', 'title', 'url', 'path')
          )
        end
      end

      # The record written out as prose, so an assistant can read it in one pass.
      def self.text_for(document, summary)
        lines = [summary['title'].to_s]

        TEXT_FIELDS.each do |label, fields|
          value = fields.filter_map { |field| document[field].presence }.first
          next if value.blank?

          lines << "#{label}: #{clamp(Array.wrap(value).join('; '))}"
        end

        lines.compact_blank.join("\n")
      end

      def self.clamp(text)
        text.length > MAX_FIELD_LENGTH ? "#{text[0, MAX_FIELD_LENGTH]}…" : text
      end
    end
  end
end
