require 'rails_helper'

RSpec.describe SearchBuilder, type: :model do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject(:search_builder) { described_class.new scope }

  describe '#groupBools' do
    let(:params) {
      {
        q_row: ['curly', 'moe', 'larry'],
        boolean_row: ['AND', 'OR']
      }
    }

    it 'returns queries chained by expected booleans' do
      expect(search_builder.groupBools(params)).to eq('( (curly AND moe)  OR larry)')
    end

    context 'missing booleans' do
      let(:params) {
        {
          q_row: ['curly', 'moe', 'larry'],
          boolean_row: ['AND']
        }
      }

      it 'defaults missing booleans to "AND"' do
        expect(search_builder.groupBools(params)).to eq('( (curly AND moe)  AND larry)')
      end
    end
  end
end
