require 'rails_helper'

describe 'BentoSearch::SolrEngineSingle' do
  let(:solr_engine_single) { BentoSearch::SolrEngineSingle.new }

  describe '#search' do
    it 'returns a BentoSearch::Results object with expected attributes' do
      search_results = solr_engine_single.search('science')
      expect(search_results.class).to eq(BentoSearch::Results)
      expect(search_results.total_items).to eq(1)
      results_by_format = search_results[0].custom_data
      expect(results_by_format.count).to eq(3)
      expect(results_by_format.map { |g| "#{g['groupValue']}: #{g['doclist']['numFound']}" }).
        to eq(['Book: 19', 'Journal/Periodical: 6', 'Database: 2'])
      expect(results_by_format[0]['doclist']['docs'][0]['fulltitle_display']).to eq('The sweet science')
    end
  end
end
