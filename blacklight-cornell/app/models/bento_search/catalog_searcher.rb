class BentoSearch::CatalogSearcher
  include Blacklight::Searchable

  def initialize(search_params)
    @search_params = search_params
  end

  def search_response
    (response, _deprecated_document_list) = search_service.search_results
    response
  end

  private

  def blacklight_config
    CatalogController.blacklight_config
  end

  def search_state
    Blacklight::SearchState.new(@search_params, blacklight_config)
  end

  def search_service_class
    Blacklight::SearchService
  end
end
