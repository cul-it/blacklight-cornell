# frozen_string_literal: true

module BlacklightMcp
  # What a facet is called on the way in and out of this endpoint.
  #
  # Blacklight identifies a facet by its Solr field: `language_facet`,
  # `fast_geo_facet`, `lc_callnum_facet`, `subject_content_facet`. Those are the
  # catalog's plumbing. This endpoint is meant for students, and an assistant
  # that says "I filtered by fast_geo_facet" has leaked an implementation detail
  # nobody outside the library needs to know.
  #
  # So the tools speak the labels the catalog already shows a person -- "Subject:
  # Region", "Call Number", "Fiction/Non-Fiction" -- and translate to the Solr
  # field on the way through. The labels come from catalog_controller.rb, so they
  # match the facet headings on the website and there is no second list.
  #
  #   MCP_SOLR_FACETS_DISPLAY=true    advertise the raw Solr field names instead
  #
  # Off (the default) is the student-facing behaviour. Turn it on for debugging,
  # or if a client is pinned to the Solr names.
  #
  # Input is lenient either way: a caller may send the readable name in any case,
  # or the Solr field. Only what this endpoint *advertises* changes.
  #
  # Tool schemas are built when the classes load, so the variable takes effect at
  # boot rather than per request.
  module FacetNames
    TRUTHY = %w[1 true yes on].freeze

    module_function

    def solr_names?
      TRUTHY.include?(ENV.fetch('MCP_SOLR_FACETS_DISPLAY', '').to_s.strip.downcase)
    end

    # What this endpoint calls the facet stored in `field`.
    def public_name(field)
      return field.to_s if solr_names?

      CatalogOptions.label_for_facet(field)
    end

    # Every facet a caller may filter on, named the way the tools advertise them.
    def public_names(fields = CatalogOptions.filterable_facet_field_keys)
      Array(fields).map { |field| public_name(field) }
    end

    def public_range_names
      public_names(CatalogOptions.range_facet_field_keys)
    end

    # The Solr field behind a name a caller sent, or nil if there is no such
    # facet. Accepts the readable name in any case, and the Solr field itself so
    # that a client written against the old vocabulary keeps working.
    def resolve(name)
      wanted = name.to_s.strip
      return nil if wanted.empty?
      return wanted if CatalogOptions.facet_field?(wanted)

      by_label[wanted.downcase]
    end

    # Rebuilt per call, like everything else in CatalogOptions: the catalog's
    # configuration is the only source of truth, and it is cheap to read.
    def by_label
      CatalogOptions.facet_fields.each_with_object({}) do |(key, field), map|
        label = field.label.to_s.downcase
        map[label] = key.to_s unless label.empty? || map.key?(label)
      end
    end
  end
end
