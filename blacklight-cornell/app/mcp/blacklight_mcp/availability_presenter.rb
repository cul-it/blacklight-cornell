# frozen_string_literal: true

module BlacklightMcp
  # Answers "can I actually get this right now" for one record.
  #
  # Everything here is read off the Solr document -- the same holdings, item and
  # access fields the record page draws its availability panel from. There is no
  # extra call to FOLIO, so this can't disagree with the website and can't add a
  # second service to the critical path.
  #
  # The fields are populated by the indexer, not by this app, so every one of
  # them is parsed defensively: a record with no holdings, a field that is a
  # bare string where another record has an array, or malformed JSON all have to
  # produce an answer rather than an exception.
  class AvailabilityPresenter
    # The FOLIO item status that means someone can walk up and take it off the
    # shelf. Every other status is reported in the item's own words rather than
    # translated, because guessing wrong here sends a student across campus for
    # nothing.
    ON_SHELF = 'Available'

    # Item-level detail is the point of this tool, but a serial with hundreds of
    # bound volumes would swamp the reply. Past this many, report the counts and
    # let get_record supply the rest.
    MAX_ITEMS_PER_HOLDING = 20

    def initialize(document, base_url: nil)
      @document = document
      @base_url = base_url
    end

    def to_h
      ResultPresenter.document(document, base_url: base_url).merge(
        'online' => online?,
        'online_access' => online_access,
        'available_now' => available_now?,
        'summary' => summary,
        'copies' => copies,
        'notes' => availability['notes'].presence
      ).compact
    end

    private

    attr_reader :document, :base_url

    # --- the one-line answer -------------------------------------------------

    def summary
      parts = []
      parts << "Online (#{online_access.size} link#{'s' if online_access.size != 1})" if online?
      parts << shelf_summary if copies.any?
      parts.compact!

      parts.any? ? parts.join('. ') : 'No holdings are listed for this record in the catalog.'
    end

    def shelf_summary
      on_shelf = copies.select { |copy| on_shelf?(copy) }
      if on_shelf.any?
        where = places(on_shelf)
        return where ? "On the shelf now at #{where}" : 'On the shelf now'
      end

      statuses = copies.filter_map { |copy| copy['status'].presence }.uniq
      held_at = places(copies)

      if statuses.any?
        return "Held at #{held_at}, none on the shelf right now (#{statuses.to_sentence})" if held_at

        "None on the shelf right now (#{statuses.to_sentence})"
      elsif held_at
        "Held at #{held_at}; the catalog does not report a current status"
      end
    end

    # nil, not false, when nothing in the record says either way -- "we don't
    # know" and "not available" are different answers to a student.
    def available_now?
      return true if online?

      states = copies.map { |copy| on_shelf?(copy) }
      return true if states.include?(true)
      return false if states.include?(false)

      nil
    end

    # A copy is on the shelf when its own item count says so. Records with no
    # holdings never get a count -- availability_json only sorts locations into
    # availAt and unavailAt -- so there `status` is the whole signal, and
    # reading only the count would report every one of them as checked out.
    # nil when the copy carries neither, so "unknown" survives as far as
    # available_now?.
    def on_shelf?(copy)
      return copy['available_items'].to_i.positive? if copy.key?('available_items')

      copy['status'] == ON_SHELF if copy.key?('status')
    end

    # --- online access -------------------------------------------------------

    def online?
      online_access.any? || availability['online'] == true
    end

    # Two places carry access links: the record's own url_access_json, and the
    # electronic holdings. A record may have either, or both naming the same
    # URL, so they are merged and de-duplicated.
    def online_access
      @online_access ||= begin
        seen = Set.new

        (parse_each(document['url_access_json']) + holdings_links).filter_map do |entry|
          next unless entry.is_a?(Hash) && entry['url'].present?
          next unless seen.add?(entry['url'].to_s)

          { 'url' => entry['url'].to_s, 'description' => entry['description'].presence }.compact
        end
      end
    end

    def holdings_links
      holdings.each_value.flat_map do |holding|
        next [] unless holding.is_a?(Hash) && holding['active'] != false

        Array(holding['links']).select { |link| link.is_a?(Hash) }
      end
    end

    # --- physical copies -----------------------------------------------------

    # One entry per holding: where it sits, under what call number, and how many
    # of its items are actually on the shelf.
    def copies
      @copies ||= holdings.any? ? holdings_copies : availability_copies
    end

    def holdings_copies
      holdings.filter_map do |holding_id, holding|
        next unless holding.is_a?(Hash)
        next if holding['active'] == false
        # An electronic holding is not a copy on a shelf. It has no location and
        # no items, only links, which online_access already reports. Left in, it
        # turns an ebook into "held at the library, status unknown".
        next if holding['online'] == true

        items = items_for(holding_id)
        copy = {
          'library' => location_name(holding['location'], 'library'),
          'location' => location_name(holding['location'], 'name'),
          'call_number' => holding['call'].presence
        }.compact

        copy.merge!(item_counts(holding, items))
        copy['items'] = items.first(MAX_ITEMS_PER_HOLDING).map { |item| item_summary(item) } if items.any?
        copy['more_items'] = items.size - MAX_ITEMS_PER_HOLDING if items.size > MAX_ITEMS_PER_HOLDING
        copy
      end
    end

    # Counts come from the items when the record carries them, and from the
    # holding's own tally when it doesn't. `status` is only set when every item
    # agrees, so a mixed holding doesn't get flattened into one misleading word.
    def item_counts(holding, items)
      counts = holding['items'].is_a?(Hash) ? holding['items'] : {}

      if items.any?
        statuses = items.map { |item| item_status(item) }.uniq
        { 'total_items' => items.size,
          'available_items' => items.count { |item| item_status(item) == ON_SHELF },
          'status' => (statuses.first if statuses.one?) }.compact
      elsif counts['count'].present?
        { 'total_items' => counts['count'].to_i, 'available_items' => counts['avail'].to_i }
      else
        {}
      end
    end

    def item_summary(item)
      {
        'status' => item_status(item),
        'enumeration' => item['enum'].presence,
        'copy' => item['copy'].presence,
        'call_number' => item['call'].presence,
        'location' => location_name(item['location'], 'name'),
        'loan_type' => nested_value(item['loanType'], 'name')
      }.compact
    end

    def item_status(item)
      nested_value(item['status'], 'status') || nested_value(item['status'], 'name') ||
        (item['status'] if item['status'].is_a?(String))
    end

    # When a record has no holdings data, availability_json still names the
    # locations and call numbers. It carries no item counts, so these entries
    # deliberately have no `available_items` key: unknown, not zero.
    def availability_copies
      %w[availAt unavailAt].flat_map do |key|
        values = availability[key]
        next [] unless values.is_a?(Hash)

        values.map do |location, call_number|
          { 'library' => location.to_s,
            'call_number' => call_number.presence,
            'status' => (key == 'availAt' ? ON_SHELF : 'Not on the shelf') }.compact
        end
      end
    end

    # --- the raw fields ------------------------------------------------------

    def availability
      @availability ||= parse_one(document['availability_json']) || {}
    end

    def holdings
      @holdings ||= parse_one(document['holdings_json']) || {}
    end

    def items
      @items ||= parse_one(document['items_json']) || {}
    end

    def items_for(holding_id)
      Array(items[holding_id]).select { |item| item.is_a?(Hash) && item['active'] != false }
    end

    # --- parsing -------------------------------------------------------------

    # These fields hold JSON inside a Solr string, and some are multi-valued, so
    # the same field arrives as a String on one record and an Array on the next.
    def parse_one(value)
      value = value.first if value.is_a?(Array)
      return value if value.is_a?(Hash)
      return nil if value.blank?

      parsed = JSON.parse(value.to_s)
      parsed.is_a?(Hash) ? parsed : nil
    rescue JSON::ParserError
      Rails.logger.warn("[mcp] unparseable holdings field on record #{document.id}")
      nil
    end

    def parse_each(value)
      Array(value).filter_map do |entry|
        next entry if entry.is_a?(Hash)

        begin
          JSON.parse(entry.to_s)
        rescue JSON::ParserError
          nil
        end
      end
    end

    def location_name(location, key)
      nested_value(location, key)
    end

    def nested_value(hash, key)
      hash[key].presence if hash.is_a?(Hash) && hash[key].is_a?(String)
    end

    # Only places the record actually names. A copy with no library is not worth
    # inventing one for: "the library" reads as a fact rather than a shrug.
    def places(copies)
      names = copies.filter_map { |copy| copy['library'].presence }.uniq
      names.any? ? names.to_sentence : nil
    end
  end
end
