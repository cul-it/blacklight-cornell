require 'rails_helper'

describe 'BentoSearch::InstitutionalRepositoriesEngine' do
  let(:ir_engine) { BentoSearch::InstitutionalRepositoriesEngine.new }

  describe '#search' do
    it 'returns a BentoSearch::Results object' do
      search_results = ir_engine.search('torts')
      expect(search_results).to be_present
      expect(search_results.class).to eq(BentoSearch::Results)
    end

    context 'quoted query' do
      it 'returns a BentoSearch::Results object' do
        search_results = ir_engine.search('"torts"')
        expect(search_results).to be_present
        expect(search_results.class).to eq(BentoSearch::Results)
      end
    end
  end
end
