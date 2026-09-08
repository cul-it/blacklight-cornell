# frozen_string_literal: true

module BlacklightMcp
  # Walks the shelf: the separate Solr collection holding one entry per item in
  # call-number order, which is what the catalog's own /get_previous and
  # /get_next drive.
  #
  # This is the one tool that does not go through Blacklight::SearchService, and
  # it cannot: shelf order is not a question the catalog index can answer. That
  # index has one row per bib record; a shelf has one place per item, and a title
  # with four copies sits in four places. The browse collection is built for
  # exactly this and the catalog already relies on it.
  #
  # The range trick is the same one BlacklightCornell::Browse#browse_solr uses --
  # ["X" TO *] forwards against the `browse` handler, [* TO "X"} backwards
  # against `reverse`. The connection is built here rather than borrowed from
  # there for one reason: that one has no timeouts, and an MCP request must not
  # be able to hold a Puma thread open indefinitely.
  #
  # BlacklightCornell::VirtualBrowse#get_document_details is deliberately not
  # used. It fetches a cover image from Google Books for every row, which is an
  # outbound HTTP call per result -- fine for a page rendering asynchronously,
  # not fine inside a tool call.
  class CallNumberBrowse
    MAX_LIMIT = 50
    DEFAULT_LIMIT = 10

    FORWARD = 'forward'
    BACKWARD = 'backward'
    DIRECTIONS = [FORWARD, BACKWARD].freeze

    class << self
      def entries(call_number:, direction: FORWARD, limit: DEFAULT_LIMIT)
        point = clean(call_number)
        raise InvalidArgument, 'call_number cannot be blank' if point.blank?

        response = query(point, direction, limit)
        Array(response.dig('response', 'docs')).map { |doc| entry(doc) }
      end

      private

      # Solr range syntax, so a quote or a backslash in the call number would
      # break the query rather than search for itself. The catalog's own browse
      # drops them the same way.
      def clean(call_number)
        call_number.to_s.gsub('\\', ' ').gsub('"', ' ').strip
      end

      def query(point, direction, limit)
        backward = direction.to_s == BACKWARD
        range = backward ? "[* TO \"#{point}\"}" : "[\"#{point}\" TO *]"

        connection.get(backward ? 'reverse' : 'browse',
                       params: { q: range, rows: limit, start: 0, wt: :ruby })
      rescue *timeout_errors
        # Reported the way a Solr timeout from the catalog path is, so the tools
        # give one answer for "the index did not come back in time".
        raise Blacklight::Exceptions::RepositoryTimeout, 'call number browse timed out'
      end

      # One row, shaped like the catalog's own call number browse page: call
      # number, citation, format, availability. Those four are always present,
      # even when empty -- a caller lining rows up should never have to tell
      # "this record has no citation" apart from "this key is missing".
      #
      # `bibid` is the catalog id, so any row can be handed straight to
      # get_record, fetch or check_availability for more than the shelf shows.
      def entry(doc)
        id = doc['bibid'].to_s
        access = Array(doc['online'])
        holdings = parse_json(doc['availability_json'])

        {
          'call_number' => doc['callnum_display'].presence,
          'citation' => citation(doc['cite_preescaped_display']),
          'format' => scalar(doc['format']),
          'availability' => availability(holdings, access),
          'status' => status(holdings, access)
        }.merge(
          {
            'title' => scalar(doc['fulltitle_display']),
            'library' => library(holdings),
            'online' => access.include?('Online'),
            'id' => id.presence,
            'path' => ("/catalog/#{id}" if id.present?)
          }.compact
        )
      end

      # Stored with markup for the browse page to render; a tool wants the words.
      def citation(value)
        text = scalar(value)
        return nil if text.blank?

        # Tags first, then entities: unescaping first could turn a literal
        # "&lt;b&gt;" in the data into a tag that then gets stripped.
        CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(text)).squish.presence
      end

      # The same availAt / unavailAt shape the catalog's own availability panel
      # reads, said in a sentence. As of the last indexing, like everything else
      # here -- check_availability is the tool for item-level detail.
      def availability(holdings, access)
        online = access.include?('Online')
        here = (holdings['availAt'] || {}).keys
        out = (holdings['unavailAt'] || {}).keys

        parts = []
        parts << 'Online' if online
        parts << "On the shelf at #{here.to_sentence}" if here.any?
        parts << "Not on the shelf at #{out.to_sentence}" if out.any?

        parts.presence&.join('. ') || 'Not reported'
      end

      # The same answer as `availability` in two or three words, for a column in a
      # table where the sentence would not fit.
      def status(holdings, access)
        return 'Online' if access.include?('Online')
        return 'On the shelf' if (holdings['availAt'] || {}).any?
        return 'Not on the shelf' if (holdings['unavailAt'] || {}).any?

        'Not reported'
      end

      # Which library holds it, which the browse page prints under each row. The
      # location field on these documents is usually empty; the library name is
      # inside availability_json.
      def library(holdings)
        names = %w[availAt unavailAt].flat_map { |key| (holdings[key] || {}).keys }

        names.uniq.presence&.to_sentence
      end

      def parse_json(value)
        parsed = JSON.parse(scalar(value).to_s)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError, TypeError
        {}
      end

      def scalar(value)
        value.is_a?(Array) ? value.first : value
      end

      def connection
        @connection ||= RSolr.connect(
          url: "#{base_url}/#{ENV.fetch('BROWSE_INDEX_CALLNUMBER', 'callnum')}",
          # The same ceilings the catalog path uses. Without them this call has
          # none at all.
          timeout: SearchRunner::SOLR_TIMEOUT,
          open_timeout: SearchRunner::SOLR_OPEN_TIMEOUT
        )
      end

      # Same derivation as BlacklightCornell::Browse. The URL carries Solr
      # credentials, so it must never reach a log or an error message.
      def base_url
        Blacklight.connection_config[:url].gsub(%r{/solr/.*}, '/solr')
      end

      def timeout_errors
        [Faraday::TimeoutError, Faraday::ConnectionFailed].tap do |errors|
          errors << RSolr::Error::Timeout if defined?(RSolr::Error::Timeout)
        end
      end
    end
  end
end
