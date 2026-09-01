# frozen_string_literal: true

module BlacklightMcp
  # Answers "what can this catalog be asked for?" -- which search fields,
  # facets, sorts and date ranges exist.
  #
  # It reads the catalog's own settings every time, so adding a facet or sort in
  # catalog_controller.rb is all it takes to make it available here. There's no
  # second list to keep in sync.
  #
  # Callers always name it, like CatalogOptions.search_field_keys. That's on
  # purpose: these are common words like `search_fields`, and mixing them into
  # other classes would let them quietly collide.
  module CatalogOptions
    extend self

    # How two advanced search rows are joined. Same list as the dropdown in
    # app/views/advanced_search/_form_rows.html.erb.
    BOOLEANS = %w[AND OR NOT].freeze

    # How the words inside one row are matched. Same list as the dropdown in
    # _form_rows.html.erb.
    OPS = {
      'AND' => 'all of these words (default)',
      'OR' => 'any of these words',
      'phrase' => 'this exact phrase',
      'begins_with' => 'begins with'
    }.freeze

    # Not real fields -- just the "---" divider lines in the dropdown.
    SEPARATOR_PREFIX = 'separator_'

    # All of the catalog's settings. Named to match Blacklight's own method.
    def blacklight_config
      CatalogController.blacklight_config
    end

    # Every field you can search in, keyed by the value to send.
    def search_fields
      blacklight_config.search_fields.reject { |key, _| key.to_s.start_with?(SEPARATOR_PREFIX) }
    end

    def search_field_keys
      search_fields.keys.map(&:to_s)
    end

    # The fields the /advanced page offers. Prefer these; the rest mostly exist
    # for links inside search results.
    def advanced_search_fields
      search_fields.select { |_key, field| field.include_in_advanced_search != false }
    end

    def sort_fields
      blacklight_config.sort_fields
    end

    def sort_field_keys
      sort_fields.keys.map(&:to_s)
    end

    def default_sort
      blacklight_config.default_sort_field&.key.to_s
    end

    # Every facet, including ones the sidebar hides but you can still filter on.
    def facet_fields
      blacklight_config.facet_fields
    end

    def facet_field_keys
      facet_fields.keys.map(&:to_s)
    end

    # Facets you filter by picking values. Leaves out date ranges (which take a
    # start and end year) and "date acquired" (which takes fixed choices).
    def filterable_facet_fields
      facet_fields.reject { |_key, field| field.range || field.query }
    end

    def filterable_facet_field_keys
      filterable_facet_fields.keys.map(&:to_s)
    end

    # Facets you filter with a start and end value, like publication year.
    def range_facet_fields
      facet_fields.select { |_key, field| field.range }
    end

    def range_facet_field_keys
      range_facet_fields.keys.map(&:to_s)
    end

    # The facets the /advanced page shows, in the order it shows them.
    def advanced_facet_fields
      facet_fields.select { |_key, field| field.include_in_advanced_search }
                  .sort_by { |_key, field| field.advanced_search_order.to_i }
                  .to_h
    end

    def query_facet_fields
      facet_fields.select { |_key, field| field.query }
    end

    def search_field?(key)
      search_field_keys.include?(key.to_s)
    end

    def facet_field?(key)
      facet_field_keys.include?(key.to_s)
    end

    def range_facet_field?(key)
      range_facet_field_keys.include?(key.to_s)
    end

    def label_for_facet(key)
      facet_fields[key.to_s]&.label || key.to_s
    end

    # Takes either the sort's id or the label a person sees ("year descending")
    # and returns the id. Returns nil if it isn't a real sort.
    def normalize_sort(value)
      return nil if value.blank?

      wanted = value.to_s.strip
      return wanted if sort_fields.key?(wanted)

      match = sort_fields.find { |_key, field| field.label.to_s.casecmp?(wanted) }
      match&.first
    end

    def sort_options
      sort_fields.map { |key, field| { 'sort' => key.to_s, 'label' => field.label.to_s } }
    end
  end
end
