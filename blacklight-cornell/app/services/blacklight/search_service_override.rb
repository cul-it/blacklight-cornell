# frozen_string_literal: true

# Based on the Module#prepend pattern in ruby.
# Uses the to_prepare Rails hook in application.rb to inject this module to override Blacklight::SearchService
# SearchService returns search results from the repository
module Blacklight
  module SearchServiceOverride
    # Overrides blacklight to default to custom BlacklightCornell::SearchState
    def initialize(config:, search_state: nil, user_params: nil, search_builder_class: config.search_builder_class, **context)
      @blacklight_config = config
      @search_state = search_state || BlacklightCornell::SearchState.new(user_params || {}, config)
      @user_params = @search_state.params
      @search_builder_class = search_builder_class
      @context = context
    end

    # Overrides blacklight to handle search limit exceeded condition
    # a solr query method
    # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used.
    # @return [Blacklight::Solr::Response] the solr response object
    # added exceeded argument for DISCOVERYACCESS-5854, deep paging (tlw72).
    def search_results(exceeded = false)

      # if the search limit has been exceeded, set the page param to the last viewable page
      if exceeded
          search_limit = Rails.configuration.search_limit
          per_page_i = @user_params[:per_page].present? ? @user_params[:per_page].to_i : 20
          last_page = search_limit/per_page_i
          @user_params[:page] = last_page
          @search_state.params.merge(@user_params)
      end

      builder = search_builder.with(search_state)
      builder.page = search_state.page
      builder.rows = search_state.per_page

      builder = yield(builder) if block_given?
      response = repository.search(builder)

      if response.grouped? && grouped_key_for_results
        [response.group(grouped_key_for_results), []]
      elsif response.grouped? && response.grouped.length == 1
        [response.grouped.first, []]
      else
        [response, response.documents]
      end
    end

    # Overrides blacklight to use custom BlacklightCornell::SearchState
    # Get the previous and next document from a search result
    # @return [Blacklight::Solr::Response, Array<Blacklight::SolrDocument>] the solr response and a list of the first and last document
    def previous_and_next_documents_for_search(index, request_params, extra_controller_params = {})
      p = previous_and_next_document_params(index)
      new_state = request_params.is_a?(BlacklightCornell::SearchState) ? request_params : BlacklightCornell::SearchState.new(request_params, blacklight_config)
      query = search_builder.with(new_state).start(p.delete(:start)).rows(p.delete(:rows)).merge(extra_controller_params).merge(p)
      response = repository.search(query)
      document_list = response.documents

      # only get the previous doc if there is one
      prev_doc = document_list.first if index > 0
      next_doc = document_list.last if (index + 1) < response.total
      [response, [prev_doc, next_doc]]
    end
  end
end
