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

  describe '#render_advanced_constraints_query' do
    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
        allow(controller).to receive(:search_state_class).and_return(BlacklightCornell::SearchState)
        allow(helper).to receive(:search_state).and_return(CatalogController.search_state_class.new(params, blacklight_config, helper))
        allow(helper).to receive(:search_action_path) { |*args| search_catalog_url *args }
      end
    end

    context 'single query row' do
      before do
        without_partial_double_verification do
          allow(helper).to receive(:default_search_field).and_return(blacklight_config.default_search_field)
        end
      end

      it 'returns expected constraint links' do
        params = { q_row: ['pickles'],
                  op_row: ['AND'],
                  search_field_row: ['title'],
                  boolean_row: {} }
        constraints_html = helper.render_advanced_constraints_query(params)
        constraints_doc = Nokogiri::HTML(constraints_html)
        link_nodes = constraints_doc.css('a')
        expect(link_nodes.count).to eq(1)

        # Query constraint
        expect(link_nodes[0].content.strip.gsub(/\s+/, ' ')).to eq('Title: pickles')
        # For some reason search_field remains in the params
        expect(link_nodes[0]['href']).to eq(search_catalog_url({ search_field: 'title' }))
      end
    end

    context 'multiple query rows' do
      before do
        without_partial_double_verification do
          allow(helper).to receive(:blacklight_config) { blacklight_config }
          allow(helper).to receive(:search_field_def_for_key).with('title') { blacklight_config.search_fields['title'] }
          allow(helper).to receive(:search_field_def_for_key).with('all_fields') { blacklight_config.search_fields['all_fields'] }
          allow(helper).to receive(:search_field_def_for_key).with('notes') { blacklight_config.search_fields['notes'] }
        end
      end

      it 'returns expected constraint links' do
        params = { q_row: ['pickles', 'cheese', 'toast'],
                  op_row: ['AND', 'AND', 'begins_with'],
                  search_field_row: ['title', 'all_fields', 'notes'],
                  boolean_row: { '1' => 'OR', '2' => 'AND' },
                  f: { 'format' => ['Book'], 'language_facet' => ['English', 'French'] },
                  f_inclusive: { 'language_facet' => ['English', 'French'] } }
        constraints_html = helper.render_advanced_constraints_query(params)
        constraints_doc = Nokogiri::HTML(constraints_html)
        link_nodes = constraints_doc.css('a')
        expect(link_nodes.count).to eq(7)

        # First query constraint
        expect(link_nodes[0].content.strip.gsub(/\s+/, ' ')).to eq('Title: pickles')
        removed_query_params = params.deep_dup
        removed_query_params[:q_row].delete_at(0)
        removed_query_params[:op_row].delete_at(0)
        removed_query_params[:search_field_row].delete_at(0)
        removed_query_params[:boolean_row] = { '1' => 'AND' }
        expect(link_nodes[0]['href']).to eq(search_catalog_path(removed_query_params))

        # Second query constraint
        expect(link_nodes[1].content.strip.gsub(/\s+/, ' ')).to eq('OR All Fields: cheese')
        removed_query_params = params.deep_dup
        removed_query_params[:q_row].delete_at(1)
        removed_query_params[:op_row].delete_at(1)
        removed_query_params[:search_field_row].delete_at(1)
        removed_query_params[:boolean_row] = { '1' => 'AND' }
        expect(link_nodes[1]['href']).to eq(search_catalog_path(removed_query_params))

        # Third query constraint
        expect(link_nodes[2].content.strip.gsub(/\s+/, ' ')).to eq('AND Notes: toast')
        removed_query_params = params.deep_dup
        removed_query_params[:q_row].delete_at(2)
        removed_query_params[:op_row].delete_at(2)
        removed_query_params[:search_field_row].delete_at(2)
        removed_query_params[:boolean_row] = { '1' => 'OR' }
        expect(link_nodes[2]['href']).to eq(search_catalog_path(removed_query_params))

        # Filter constraints from search results facets
        expect(link_nodes[3].content.strip.gsub(/\s+/, ' ')).to eq('Format: Book')
        removed_f_format_param = params[:f].except('format')
        expect(link_nodes[3]['href']).to eq(search_catalog_url(params.merge({ f: removed_f_format_param })))
        expect(link_nodes[4].content.strip.gsub(/\s+/, ' ')).to eq('Language: English')
        removed_f_english_param = { 'format' => ['Book'], 'language_facet' => ['French'] }
        expect(link_nodes[4]['href']).to eq(search_catalog_url(params.merge({ f: removed_f_english_param })))
        expect(link_nodes[5].content.strip.gsub(/\s+/, ' ')).to eq('Language: French')
        removed_f_french_param = { 'format' => ['Book'], 'language_facet' => ['English'] }
        expect(link_nodes[5]['href']).to eq(search_catalog_url(params.merge({ f: removed_f_french_param })))

        # Filter constraint from advanced search form
        expect(link_nodes[6].content.strip.gsub(/\s+/, ' ')).to eq('Language: English OR French')
        expect(link_nodes[6]['href']).to eq(search_catalog_url(params.except(:f_inclusive)))
      end
    end
  end
end
