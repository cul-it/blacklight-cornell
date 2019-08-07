# frozen_string_literal: true
# SearchService returns search results from the repository
class CornellSearchService < Blacklight::SearchService

  # a solr query method
  # @param [Hash] params ({}) the user provided parameters (e.g. query, facets, sort, etc)
  # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used.
  # @return [Blacklight::Solr::Response] the solr response object
  def search_results(params)
    builder = search_builder.with(params)
    builder.page = params[:page] if params[:page]
    builder.rows = (params[:per_page] || params[:rows]) if params[:per_page] || params[:rows]

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
end
