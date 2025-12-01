require 'rails_helper'

describe 'BentoSearch::BestBetEngine' do
  let(:best_bet_engine) { BentoSearch::BestBetEngine.new }

  describe '#search' do
    context 'query matches best bet keyword' do
      it 'returns a BentoSearch::Results object' do
        search_results = best_bet_engine.search('biosis citation')
        expect(search_results).to be_present
        expect(search_results.class).to eq(BentoSearch::Results)
      end

      context 'quoted query' do
        it 'returns a BentoSearch::Results object' do
          search_results = best_bet_engine.search('"biosis citation"')
          expect(search_results).to be_present
          expect(search_results.class).to eq(BentoSearch::Results)
        end
      end
    end

    context 'query does not match best bet keyword' do
      it 'returns an empty BentoSearch::Results object' do
        search_results = best_bet_engine.search('no_matches_here')
        expect(search_results.class).to eq(BentoSearch::Results)
        expect(search_results.count).to eq(0)
      end
    end
  end
end
