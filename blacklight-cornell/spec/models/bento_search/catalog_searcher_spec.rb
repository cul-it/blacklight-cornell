require 'rails_helper'

describe 'BentoSearch::CatalogSearcher' do
  let(:catalog_searcher) { BentoSearch::CatalogSearcher.new(search_params) }
  
  describe '#search_response' do
    context 'when bento param is true' do
      let(:search_params) { { q: 'cats dogs', search_field: 'all_fields', bento: true } }

      it 'returns a blacklight GroupResponse object' do
        expect(catalog_searcher.search_response.class).to eq(Blacklight::Solr::Response::GroupResponse)
      end
    end

    context 'when bento param is not set' do
      let(:search_params) { { q: 'cats dogs', search_field: 'all_fields' } }

      it 'returns a standard blacklight Response object' do
        expect(catalog_searcher.search_response.class).to eq(Blacklight::Solr::Response)
      end
    end
  end
end
