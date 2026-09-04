# frozen_string_literal: true

module BlacklightMcp
  # Runs a set of search parameters through the catalog's own search code.
  #
  # This is the exact path CatalogController uses, so results match the website.
  # Nothing here writes anything.
  class SearchRunner
    include Blacklight::Searchable

    # How long an MCP request will wait on Solr. Shorter than the website's on
    # purpose: a person looking at a spinner will wait, but an AI client that
    # gets no answer retries, and a slow query holding a Puma thread is exactly
    # how MCP traffic starves the human catalog. Failing fast gives the client
    # something it can act on.
    SOLR_OPEN_TIMEOUT = Integer(ENV.fetch('MCP_SOLR_OPEN_TIMEOUT', 2))
    SOLR_TIMEOUT = Integer(ENV.fetch('MCP_SOLR_TIMEOUT', 5))

    attr_reader :params

    class << self
      # The catalog's settings with MCP's own Solr timeouts, built once per
      # process. Copying the configuration is not cheap and these values never
      # change while it runs; a code reload replaces this class, and the copy
      # with it.
      def blacklight_config
        @blacklight_config ||= CatalogController.blacklight_config.deep_copy.tap do |config|
          config.connection_config = config.connection_config.merge(
            open_timeout: SOLR_OPEN_TIMEOUT,
            timeout: SOLR_TIMEOUT,
            # Retrying a struggling Solr adds load at the worst possible moment.
            # One attempt, then an honest failure.
            retry_503: false
          )
        end
      end
    end

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

    # Several records in one Solr round trip. Ids that don't exist are simply
    # missing from the result rather than an error, so the caller can report
    # them alongside the ones that were found.
    #
    # `fl: '*'` is load-bearing. Fetching many records goes through the search
    # path, which returns only the fields the results page displays. Holdings
    # and item data are show-page fields, so without this they are absent and
    # anything reading them sees an empty record rather than an error.
    def documents(ids)
      Array(search_service.fetch(Array(ids).map { |id| id.to_s.strip }, fl: '*'))
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
      self.class.blacklight_config
    end

    # Built once and reused: the search code edits these parameters as it runs,
    # so making a fresh copy each time would redo that work.
    def search_state
      @search_state ||= CatalogController.search_state_class.new(params, blacklight_config)
    end
  end
end
