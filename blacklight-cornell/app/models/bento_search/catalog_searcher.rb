class BentoSearch::CatalogSearcher
  include Blacklight::Searchable

  def initialize(search_params)
    @search_params = search_params
  end

  def search_response
    search_service.search_results
  end

  private

  def blacklight_config
    CatalogController.blacklight_config
  end

  def search_state
    CatalogController.search_state_class.new(@search_params, blacklight_config)
  end

  def search_service_class
    Blacklight::SearchService
  end
end
