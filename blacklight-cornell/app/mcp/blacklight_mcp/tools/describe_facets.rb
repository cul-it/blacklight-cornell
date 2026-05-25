require "json"

module BlacklightMcp
  module Tools
    # Returns the facet vocabulary Claude needs in order to filter
    # `catalog_search` calls without guessing. Reads directly from
    # CatalogController.blacklight_config — no Solr round trip required.
    class DescribeFacets < MCP::Tool
      description <<~DESC
        Return every facet field exposed by blacklight-cornell, grouped by
        whether it's user-facing or hidden/staff-only, plus the generated
        subject-by-vocabulary pattern. Optionally include a live sample of
        current values so Claude can pass exact strings to `catalog_search`
        (e.g. "Book" vs. "Books", "Journal/Periodical" vs. "Periodical").

        Call this once at the start of a session if you intend to filter.
      DESC

      # Hand-written hints layered on top of the raw blacklight_config. The
      # config only tells us field name + label + show:true/false; these
      # notes tell Claude *how* to use each facet.
      FACET_NOTES = {
        "format"                => "Material type. Single-valued in practice. Common values: Book, Journal/Periodical, Musical Score, Musical Recording, Non-musical Recording, Video, Manuscript/Archive, Map, Database, Thesis.",
        "online"                => 'Access. Usually one of "Online" or "At the Library".',
        "location"              => "Holding library / location (e.g. Olin Library, Uris Library, Library Annex). Index-sorted, large value list.",
        "author_facet"          => "Author / contributor (combined names, top-level). Use this for general author filtering.",
        "pub_date_facet"        => "Publication year. Filter via the `pub_date_range` parameter on `catalog_search` (which translates to a range query), not by listing values.",
        "language_facet"        => 'Language of the resource (e.g. "English", "French", "Chinese").',
        "fast_topic_facet"      => "FAST topical subject heading. Preferred for subject filtering — these are the headings users see in the UI as 'Subject'.",
        "fast_geo_facet"        => "FAST geographic subject heading (Subject: Region).",
        "fast_era_facet"        => "FAST chronological subject heading (Subject: Era).",
        "fast_genre_facet"      => "FAST form/genre heading (e.g. 'Biographies', 'Fiction').",
        "subject_content_facet" => "Fiction / Non-Fiction split.",
        "hierarchy_facet"       => "Hierarchical subject tree facet. Values are pipe-delimited paths.",
        "lc_callnum_facet"      => "Library of Congress call number classification, index-sorted with no value limit.",
        "acquired_dt_query"     => "Date the item was acquired. Implemented as a Solr query facet, not a date range — values like NEW_LAST_14_DAYS.",
        "format_main_facet"     => "Single-valued primary format (normalized). The bento solr engine groups on this."
      }.freeze

      # blacklight-cornell programmatically generates ~117 staff-only subject
      # facets via:
      #
      #   %w[topic genr pers corp event era geo gen sub].each do |type|
      #     %w[lc lcgft lcjsh fast aat agrovoc homoit mesh rbmscv zst local unk other].each do |source|
      #       "subject_#{type}_#{source}_facet"
      #     end
      #   end
      SUBJECT_PATTERN = {
        "field_pattern" => "subject_<type>_<source>_facet",
        "types"   => %w[topic genr pers corp event era geo gen sub],
        "sources" => %w[lc lcgft lcjsh fast aat agrovoc homoit mesh rbmscv zst local unk other],
        "note"    => "Use the most specific (type, source) pair available. The user-facing 'Subject' filter is fast_topic_facet (i.e. type=topic, source=fast). The other 116 combinations exist for staff workflows and almost never need to be queried directly."
      }.freeze

      input_schema(
        properties: {
          include_live_sample: {
            type: "boolean",
            description: "If true (default), run one blank catalog query to fetch sample facet values for the user-facing facets."
          },
          include_staff_facets: {
            type: "boolean",
            description: "If true (default), include the hidden/staff-only facets in the response."
          }
        }
      )

      class << self
        def call(server_context:, include_live_sample: true, include_staff_facets: true)
          user_facing, staff = partition_facets

          out = { "user_facing" => user_facing }
          out["staff"] = staff if include_staff_facets
          out["subject_pattern"] = SUBJECT_PATTERN

          if include_live_sample
            begin
              out["sample_values"] = live_sample_values(user_facing.keys)
            rescue => e
              server_context[:logger]&.warn("describe_facets live sample failed: #{e.message}")
              out["sample_values_error"] = e.message
            end
          end

          MCP::Tool::Response.new(
            [{ type: "text", text: JSON.pretty_generate(out) }]
          )
        end

        private

        def partition_facets
          user_facing = {}
          staff = {}
          CatalogController.blacklight_config.facet_fields.each do |field, cfg|
            entry = {
              "label" => cfg.label,
              "note"  => FACET_NOTES[field]
            }.compact
            if cfg.show == false
              staff[field] = entry
            else
              user_facing[field] = entry
            end
          end
          [user_facing, staff]
        end

        def live_sample_values(fields)
          state = CatalogController.search_state_class.new(
            { q: "*", per_page: 0 },
            CatalogController.blacklight_config
          )
          service = Blacklight::SearchService.new(
            config: CatalogController.blacklight_config,
            search_state: state
          )
          response, = service.search_results
          aggs = response.aggregations || {}

          fields.each_with_object({}) do |field, acc|
            agg = aggs[field]
            next unless agg
            items = agg.respond_to?(:items) ? agg.items : []
            values = items.first(10).map { |it| it.respond_to?(:value) ? it.value : it.to_s }
            acc[field] = values unless values.empty?
          end
        end
      end
    end
  end
end
