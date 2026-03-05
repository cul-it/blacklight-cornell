require 'rails_helper'

describe BrowseHelper do
  let(:blacklight_config) { CatalogController.blacklight_config }

  describe '#convert_to_advanced_params' do
    it 'returns empty hash when params are empty or does not contain relevant keys' do
      expect(helper.convert_to_advanced_params({})).to eq({})
      expect(helper.convert_to_advanced_params({ controller: 'catalog' })).to eq({})
    end

    it 'returns an empty q_row when q and authq are not present' do
      params = { search_field: 'journaltitle' }
      expected_params = { q_row: [''], search_field_row: ['journaltitle'] }
      expect(helper.convert_to_advanced_params(params)).to eq(expected_params)
    end

    context 'simple search' do
      it 'converts q to q_row and search_field to search_field_row' do
        params = { q: 'test query', search_field: 'title' }
        expected_params = { q_row: ['test query'], search_field_row: ['title'] }
        expect(helper.convert_to_advanced_params(params)).to eq(expected_params)
      end

      it 'adds op_row when search_field = title_starts' do
        params = { q: 'test query', search_field: 'title_starts' }
        expected_params = { q_row: ['test query'], search_field_row: ['title'], op_row: ['begins_with'] }
        expect(helper.convert_to_advanced_params(params)).to eq(expected_params)
      end
    end

    context 'bento search' do
      it 'converts q to q_row and sets default search_field' do
        params = { q: 'test query' }
        expected_params = { q_row: ['test query'], search_field_row: ['all_fields'] }
        expect(helper.convert_to_advanced_params(params)).to eq(expected_params)
      end
    end

    context 'browse' do
      it 'converts authq to q_row and browse_type to search_field_row' do
        params = { authq: 'TP640', browse_type: 'Call-Number' }
        expected_params = { q_row: ['TP640'], search_field_row: ['lc_callnum'] }
        expect(helper.convert_to_advanced_params(params)).to eq(expected_params)
      end

      it 'does not error when invalid browse_type is provided' do
        params = { authq: 'TP640', browse_type: 'InvalidType' }
        expected_params = { q_row: ['TP640'], search_field_row: [nil] }
        expect(helper.convert_to_advanced_params(params)).to eq(expected_params)
      end
    end
  end

  describe '#remove_blank_rows' do
    context 'single row query' do
      context 'query is not blank' do
        it 'removes last blank row' do
          params = helper.remove_blank_rows({ q_row: ['test', ''],
                                              op_row: ['AND', 'AND'],
                                              search_field_row: ['all_fields', 'all_fields'],
                                              boolean_row: { '1' => 'AND' } })
          expect(params).to eq({ q_row: ['test'], op_row: ['AND'], search_field_row: ['all_fields'], boolean_row: {} })
        end
      end

      context 'query is blank' do
        it 'removes blank rows' do
          params = helper.remove_blank_rows({ q_row: ['', ''],
                                              op_row: ['AND', 'AND'],
                                              search_field_row: ['all_fields', 'all_fields'],
                                              boolean_row: { '1' => 'AND' } })
          expect(params).to eq({ q_row: [], op_row: [], search_field_row: [], boolean_row: {} })
        end
      end
    end

    context 'multiple row query' do
      context 'query is not blank' do
        it 'returns expected params' do
          params = helper.remove_blank_rows({ q_row: ['pickles', 'cheese', 'toast'],
                                              op_row: ['AND', 'AND', 'begins_with'],
                                              search_field_row: ['title', 'all_fields', 'notes'],
                                              boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['pickles', 'cheese', 'toast'],
                                op_row: ['AND', 'AND', 'begins_with'],
                                search_field_row: ['title', 'all_fields', 'notes'],
                                boolean_row: { '1' => 'OR', '2' => 'AND' } })
        end
      end
      
      context 'middle query is blank' do
        it 'removes blank row' do
          params = helper.remove_blank_rows({ q_row: ['pickles', '', 'toast'],
                                              op_row: ['AND', 'AND', 'begins_with'],
                                              search_field_row: ['title', 'all_fields', 'notes'],
                                              boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['pickles', 'toast'],
                                op_row: ['AND', 'begins_with'],
                                search_field_row: ['title', 'notes'],
                                boolean_row: { '1' => 'AND' } })
        end

        it 'removes blank rows' do
          params = helper.remove_blank_rows({ q_row: ['pickles', '', '', 'sandwich'],
                                              op_row: ['AND', 'AND', 'begins_with', 'OR'],
                                              search_field_row: ['title', 'all_fields', 'notes', 'subject'],
                                              boolean_row: { '1' => 'OR', '2' => 'AND', '3' => 'NOT' } })
          expect(params).to eq({ q_row: ['pickles', 'sandwich'],
                                op_row: ['AND', 'OR'],
                                search_field_row: ['title', 'subject'],
                                boolean_row: { '1'  => 'NOT' } })
        end
      end

      context 'first query is blank' do
        it 'removes blank rows' do
          params = helper.remove_blank_rows({ q_row: ['', 'cheese', 'toast'],
                                              op_row: ['AND', 'AND', 'begins_with'],
                                              search_field_row: ['title', 'all_fields', 'notes'],
                                              boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['cheese', 'toast'],
                                op_row: ['AND', 'begins_with'],
                                search_field_row: ['all_fields', 'notes'],
                                boolean_row: { '1'  => 'AND' } })
        end
      end
    end

    context "row counts don't match" do
      context 'q_row count is less than boolean, op, or search_field row counts' do
        it 'removes extra boolean, op, or search_field rows' do
          params = helper.remove_blank_rows({ q_row: ['pickles', 'cheese'],
                                              op_row: ['AND', 'AND', 'begins_with'],
                                              search_field_row: ['title', 'all_fields', 'notes'],
                                              boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['pickles', 'cheese'],
          op_row: ['AND', 'AND'],
          search_field_row: ['title', 'all_fields'],
          boolean_row: { '1'  => 'OR' } })
        end
      end

      context 'q_row_count is more than boolean, op, or search_field row counts' do
        it 'returns params with default booleans, ops, or search_fields when missing' do
          params = helper.remove_blank_rows({ q_row: ['pickles', 'cheese', 'toast'],
                                              op_row: ['AND', 'begins_with'],
                                              search_field_row: ['title', 'notes'],
                                              boolean_row: { '1' => 'OR' } })
          expect(params).to eq({ q_row: ['pickles', 'cheese', 'toast'],
          op_row: ['AND', 'begins_with', 'AND'],
          search_field_row: ['title', 'notes', 'all_fields'],
          boolean_row: { '1'  => 'OR', '2'  => 'AND' } })
        end
      end

      context 'boolean, op, or search_field keys are completely missing' do
        it 'returns params with default booleans, ops, or search_fields' do
          params = helper.remove_blank_rows({ q_row: ['pickles', 'cheese', 'toast'] })
          expect(params).to eq({ q_row: ['pickles', 'cheese', 'toast'],
          op_row: ['AND', 'AND', 'AND'],
          search_field_row: ['all_fields', 'all_fields', 'all_fields'],
          boolean_row: { '1'  => 'AND', '2'  => 'AND' } })
        end
      end
    end
  end
end
