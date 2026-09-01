# frozen_string_literal: true

module BlacklightMcp
  # Runs a set of search parameters through the catalog's own search code.
  #
  # This is the exact path CatalogController uses, so results match the website.
  # Nothing here writes anything.
  class SearchRunner
    include Blacklight::Searchable

    attr_reader :params

    def initialize(params = {})
      @params = params
    end

    def search_results
      search_service.search_results
    end

    # Everything Solr has stored for one record.
    def document(id)
      search_service.fetch(id.to_s)
    rescue Blacklight::Exceptions::RecordNotFound, Blacklight::Exceptions::InvalidSolrID
      raise NotFound, "No catalog record found with id #{id.inspect}"
    end

    # All the values for one facet, not just the few the sidebar shows.
    def facet_results(facet_key)
      search_service.facet_field_response(facet_key)
    end

    # Shows the Solr query these parameters would produce, without running it.
    # Useful for checking a search before spending a request on it.
    def solr_params
      search_service.search_builder.with(search_state).to_h
    end

    def blacklight_config
      CatalogController.blacklight_config
    end

    # Built once and reused: the search code edits these parameters as it runs,
    # so making a fresh copy each time would redo that work.
    def search_state
      @search_state ||= CatalogController.search_state_class.new(params, blacklight_config)
    end
  end
end
