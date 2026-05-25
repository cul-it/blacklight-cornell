require "json"

module BlacklightMcp
  module Tools
    class CatalogSearch < MCP::Tool
      description <<~DESC
        Search the Cornell University Library catalog (books, journals, scores,
        recordings, etc.) via Blacklight + Solr.

        Two modes:
          * Simple — pass `query` (and optionally `search_field`).
          * Advanced — pass `advanced.rows` with one entry per search row plus
            `advanced.booleans` for the AND/OR/NOT combinators between rows.

        Default field is "all_fields" — only narrow to a specific field
        (title, author, subject, etc.) when the user clearly says so
        ("in the title", "by author X", "as a subject heading"). A query
        like 'the phrase "Sai Rollan"' has no field hint → use all_fields.

        When the field is genuinely ambiguous AND the wrong guess would
        materially change results, ask a brief clarifying question before
        calling. Example: "find John Smith" — ambiguous (author? subject?
        a person named in a book?) → ask. But for "books about climate
        change" or 'the phrase "Sai Rolland"' → just default to all_fields
        and search. Do not ask for unambiguous queries.

        Sort defaults to RELEVANCE (Solr score, then pub date, then title).
        Omit `sort` for relevance-ranked results; set it only when the user
        asks for a specific order (newest, oldest, alphabetical, etc.).

        Common filters are exposed as named params, including `format`
        (Book / Journal/Periodical / Video / Musical Score / …) and
        `language` (English / French / Chinese / …). Call `describe_facets`
        first to see exact values. Anything not in the named params can be
        passed via the generic `facets` map.

        Filters across different facet fields are AND-combined; multiple
        values for the same facet field are OR-combined.
      DESC

      # Friendly param-name aliases over the underlying Solr facet field.
      # Anything not listed here is exposed under its raw field name.
      FACET_ALIASES = {
        subject:  "fast_topic_facet",
        genre:    "fast_genre_facet",
        region:   "fast_geo_facet",
        era:      "fast_era_facet",
        language: "language_facet",
        author:   "author_facet",
        callnum:  "lc_callnum_facet",
        fiction:  "subject_content_facet"
      }.freeze

      # Facets that aren't simple value-list filters and need bespoke
      # handling. pub_date_facet → use the `pub_date_range` parameter.
      # acquired_dt_query is a Solr query-facet with fixed buckets and
      # doesn't map cleanly to a string-array filter.
      SKIP_AUTO_FACETS = %w[pub_date_facet acquired_dt_query].freeze

      # Per-row match types accepted by SearchBuilder#q_to_solr.
      # "AND" = all words must match, "OR" = any word, "phrase" = exact,
      # "begins_with" = left-anchored.
      ROW_OPS = %w[AND OR phrase begins_with].freeze

      # Boolean combinators between adjacent advanced-search rows.
      ROW_BOOLEANS = %w[AND OR NOT].freeze

      # Auto-discover the user-facing facet map from blacklight_config so
      # this list never drifts from catalog_controller.rb. Aliases above
      # rename specific fields to friendlier param names.
      NAMED_FACETS = begin
        reverse_alias = FACET_ALIASES.each_with_object({}) { |(k, v), h| h[v] = k }
        CatalogController.blacklight_config.facet_fields.each_with_object({}) do |(field, cfg), acc|
          next if cfg.show == false
          next if SKIP_AUTO_FACETS.include?(field)
          param = reverse_alias[field] || field.to_sym
          acc[param] = field
        end.freeze
      end

      # Search fields the advanced-search form would expose. Same list works
      # for simple `search_field` since SearchBuilder applies the field's
      # solr config the same way in both modes.
      SEARCH_FIELD_KEYS = CatalogController.blacklight_config.search_fields
        .reject { |_, f| f.include_in_advanced_search == false }
        .keys.freeze

      SORT_KEYS = CatalogController.blacklight_config.sort_fields.keys.freeze

      # Facets too noisy to surface in result summaries:
      # pub_date_facet is a range, lc_callnum_facet has thousands of values,
      # hierarchy_facet is pipe-delimited paths, acquired_dt_query has
      # opaque bucket names.
      SUMMARY_FACET_SKIP = %w[
        pub_date_facet
        acquired_dt_query
        lc_callnum_facet
        hierarchy_facet
      ].freeze

      # User-facing facets whose aggregations get surfaced alongside each
      # result set, so Claude can see the actual values present and either
      # narrow further or recognize a wrong-domain result set.
      SUMMARY_FACETS = CatalogController.blacklight_config.facet_fields
        .reject { |field, cfg| cfg.show == false || SUMMARY_FACET_SKIP.include?(field) }
        .map    { |field, cfg| [field, cfg.label || field] }
        .freeze

      facet_properties = NAMED_FACETS.each_with_object({}) do |(param, field), h|
        h[param] = {
          type: "array",
          items: { type: "string" },
          description: "Filter on Solr facet `#{field}`. Call `describe_facets` for known values."
        }
      end

      input_schema(
        properties: {
          query: {
            type: "string",
            description: "Plain natural-language query. Required unless `advanced` is provided."
          },
          search_field: {
            type: "string",
            description: "Optional field-scoped search for the simple `query` form.",
            enum: SEARCH_FIELD_KEYS
          },

          advanced: {
            type: "object",
            description: <<~D.strip,
              Multi-row advanced search. When set, `query` and `search_field`
              are ignored.

              IMPORTANT — two different concepts, do not confuse them:
                * `rows[].op` = how WORDS WITHIN ONE ROW are matched
                    (AND / OR / phrase / begins_with). This is the per-row
                    match-type. NOT is NOT a valid value here.
                * `booleans` = how ROWS are joined to each other
                    (AND / OR / NOT). This is where NOT belongs.

              Example — "Stephen King books but not Dark Tower":
                rows: [
                  { field: "author", op: "AND", query: "Stephen King" },
                  { field: "title",  op: "AND", query: "Dark Tower" }
                ],
                booleans: ["NOT"]
              → author:"Stephen King" NOT title:"Dark Tower"

              Example — "climate OR sustainability in subject":
                rows: [
                  { field: "subject", op: "OR", query: "climate sustainability" }
                ]
              → subject:(climate OR sustainability)

              `booleans` length must equal `rows.length - 1`.
            D
            properties: {
              rows: {
                type: "array",
                minItems: 1,
                items: {
                  type: "object",
                  properties: {
                    query: { type: "string", description: "Search term(s) for this row." },
                    field: {
                      type: "string",
                      enum: SEARCH_FIELD_KEYS,
                      description: "Which field to search. DEFAULT to `all_fields` unless the user explicitly scopes the row to a specific field. Examples: 'titles starting with...' → title; 'books by X' → author; 'subject heading climate' → subject; 'the phrase \"foo\"' (no field hint) → all_fields."
                    },
                    op: {
                      type: "string",
                      enum: ROW_OPS,
                      description: <<~OP.strip
                        How words within THIS row combine. Maps to the UI's match-type dropdown:
                          * "AND"         — "All" (every word must match; default)
                          * "OR"          — "Any" (any word matches)
                          * "phrase"      — "Phrase" (exact phrase, e.g. "Sai Rollan")
                          * "begins_with" — "Begins With" (left-anchored, e.g. titles starting with "Dark")

                        Defaults to AND. NOT is NOT a valid op — use `booleans` between rows for negation.
                      OP
                    }
                  },
                  required: ["query", "field"]
                }
              },
              booleans: {
                type: "array",
                items: { type: "string", enum: ROW_BOOLEANS },
                description: "Combinator between consecutive rows: AND, OR, or NOT. Length must equal rows.length - 1. Example: rows=[A, B] with booleans=['NOT'] produces `A NOT B`. Defaults to all-AND when omitted."
              }
            },
            required: ["rows"]
          },

          **facet_properties,

          online_only: {
            type: "boolean",
            description: "Restrict to items available online. Sets f[online][]=Online."
          },
          pub_date_range: {
            type: "object",
            description: "Inclusive publication-year range; translates to a Solr range query on pub_date_facet.",
            properties: {
              begin: { type: "integer" },
              end:   { type: "integer" }
            }
          },

          facets: {
            type: "object",
            description: "Generic catch-all facet filter map. Keys are raw Solr facet field names; values are arrays of strings. Use for anything not covered by the named parameters above (staff facets, hierarchy_facet, the 117 subject_<type>_<source>_facet fields, etc.).",
            additionalProperties: {
              type: "array",
              items: { type: "string" }
            }
          },

          sort: {
            type: "string",
            description: "Sort key. OMIT for relevance ranking (Solr score, then pub date, then title) — this is the right default for most queries. Only set this when the user asks for a specific order, e.g. 'newest first' / 'oldest first' / 'by title'.",
            enum: SORT_KEYS
          },
          per_page: { type: "integer", description: "Results per page (1–50).", minimum: 1, maximum: 50 },
          page:     { type: "integer", description: "1-indexed page number.", minimum: 1 }
        }
      )

      class << self
        def call(server_context:, query: nil, search_field: nil, advanced: nil,
                 online_only: nil, pub_date_range: nil, facets: nil,
                 sort: nil, per_page: 10, page: 1, **named_facet_args)

          if advanced.nil? && query.to_s.strip.empty?
            return error_response("catalog_search requires either `query` or `advanced.rows`.")
          end

          params = build_params(
            query: query, search_field: search_field, advanced: advanced,
            sort: sort, per_page: per_page, page: page,
            online_only: online_only, pub_date_range: pub_date_range,
            facets: facets, named_facet_args: named_facet_args
          )

          state = CatalogController.search_state_class.new(
            params, CatalogController.blacklight_config
          )
          service = Blacklight::SearchService.new(
            config: CatalogController.blacklight_config,
            search_state: state
          )
          response, documents = service.search_results

          MCP::Tool::Response.new(
            [{ type: "text", text: summarize(response, documents) }]
          )
        rescue => e
          server_context[:logger]&.error("catalog_search failed: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
          error_response("catalog_search failed: #{e.class}: #{e.message}")
        end

        private

        def build_params(query:, search_field:, advanced:, sort:, per_page:, page:,
                         online_only:, pub_date_range:, facets:, named_facet_args:)
          params = { per_page: per_page, page: page }

          if advanced
            apply_advanced!(params, advanced)
          else
            params[:q] = query
            params[:search_field] = search_field if search_field
          end

          params[:sort] = sort if sort

          merged_facets = build_facets(
            named_facet_args: named_facet_args,
            online_only: online_only,
            extra: facets
          )
          params[:f] = merged_facets if merged_facets.any?

          if pub_date_range
            range_begin = pub_date_range[:begin] || pub_date_range["begin"]
            range_end   = pub_date_range[:end]   || pub_date_range["end"]
            if range_begin || range_end
              params[:range] = {
                pub_date_facet: { begin: range_begin, end: range_end }.compact
              }
            end
          end

          params
        end

        # Translate the tool's `advanced` shape into the q_row / op_row /
        # search_field_row / boolean_row params that SearchBuilder expects.
        def apply_advanced!(params, advanced)
          rows = Array(advanced[:rows] || advanced["rows"])
          raise ArgumentError, "advanced.rows must not be empty" if rows.empty?

          params[:q_row] = rows.map { |r| (r[:query] || r["query"]).to_s }
          params[:op_row] = rows.map { |r| (r[:op] || r["op"] || "AND").to_s }
          params[:search_field_row] = rows.map { |r| (r[:field] || r["field"]).to_s }

          # SearchBuilder#remove_blank_rows reads boolean_row via
          # params.dig(:boolean_row, "<index>"), so it must be a Hash keyed
          # by stringified 1-based row index.
          booleans = Array(advanced[:booleans] || advanced["booleans"])
          params[:boolean_row] = booleans.each_with_index.each_with_object({}) do |(b, i), h|
            h[(i + 1).to_s] = b.to_s
          end
        end

        def build_facets(named_facet_args:, online_only:, extra:)
          facets = {}

          NAMED_FACETS.each do |param, solr_field|
            values = named_facet_args[param]
            facets[solr_field] = Array(values) if values && !Array(values).empty?
          end

          facets["online"] = ["Online"] if online_only

          if extra.is_a?(Hash)
            extra.each do |field, values|
              next if values.nil? || Array(values).empty?
              key = field.to_s
              facets[key] = (Array(facets[key]) + Array(values)).uniq
            end
          end

          facets
        end

        def summarize(response, documents)
          total = response.respond_to?(:total) ? response.total : documents.size
          docs = Array(documents)
          header = "Found #{total} result(s); showing #{docs.size}."
          facets_block = facet_aggregations_text(response)

          if docs.empty?
            sections = ["#{header}\n\n(no documents in response)"]
            sections << facets_block if facets_block
            return sections.join("\n\n")
          end

          lines = docs.each_with_index.map do |doc, i|
            id     = doc["id"] || doc.id
            title  = doc_value(doc, "fulltitle_display", "title_display", "title_tsim") || "(no title)"
            author = doc_value(doc, "author_display", "author_addl_display", "author_pers_roman_display", "author_corp_roman_display")
            year   = doc_value(doc, "pub_date_display", "pub_date", "pub_date_sort")
            fmt    = doc_value(doc, "format_main_facet", "format", "bib_format_display")

            <<~LINE.strip
              #{i + 1}. #{title}#{author ? " — #{author}" : ""}
                 id: #{id}#{year ? "  |  #{year}" : ""}#{fmt ? "  |  #{fmt}" : ""}
                 /catalog/#{id}
            LINE
          end

          sections = [header]
          sections << facets_block if facets_block
          sections.concat(lines)
          sections.join("\n\n")
        end

        # Surface the top values for each user-facing facet in this result
        # set. Lets the caller see what controlled-vocabulary values actually
        # exist (so they can narrow further without guessing) and spot when
        # the result set is in the wrong domain entirely — e.g. a search for
        # "metabolic bone disease" returning a fast_topic_facet dominated by
        # human-medicine headings means the query needs adjustment, not
        # more facet guessing.
        def facet_aggregations_text(response)
          aggs = response.respond_to?(:aggregations) ? (response.aggregations || {}) : {}
          return nil if aggs.empty?

          lines = SUMMARY_FACETS.filter_map do |field, label|
            agg = aggs[field]
            next unless agg.respond_to?(:items)
            items = agg.items.first(6)
            next if items.empty?

            pairs = items.map do |it|
              value = it.respond_to?(:value) ? it.value : it.to_s
              count = it.respond_to?(:hits) ? it.hits : nil
              count ? "#{value} (#{count})" : value.to_s
            end
            "  #{label.to_s.ljust(20)} [#{field}] · #{pairs.join(' · ')}"
          end

          return nil if lines.empty?

          [
            "Top facet values in this result set (pass any of these into the " \
              "corresponding named param — or the generic `facets` map keyed " \
              "by the [bracketed] Solr field — to narrow further):",
            *lines
          ].join("\n")
        end

        def doc_value(doc, *keys)
          keys.each do |k|
            v = doc[k]
            next if v.nil?
            v = v.first if v.is_a?(Array)
            return v unless v.nil? || (v.respond_to?(:empty?) && v.empty?)
          end
          nil
        end

        def error_response(msg)
          MCP::Tool::Response.new(
            [{ type: "text", text: msg }],
            error: true
          )
        end
      end
    end
  end
end
