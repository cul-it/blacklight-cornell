require 'rails_helper'

RSpec.describe AdvancedHelper, type: :helper do
  describe '#advanced_search_field_select_opts' do
    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      end
    end

    it 'returns advanced search fields from blacklight config' do
      expect(helper.advanced_search_field_select_opts).to eq([
        ['All Fields', 'all_fields'],
        ['Title', 'title'],
        ['Journal Title', 'journaltitle'],
        ['Author', 'author'],
        ['Subject', 'subject'],
        ['Call Number', 'lc_callnum'],
        ['Series', 'series'],
        ['Publisher', 'publisher'],
        ['Place of Publication', 'pubplace'],
        ['Publisher Number/Other Identifier', 'number'],
        ['ISBN/ISSN', 'isbnissn'],
        ['Notes', 'notes'],
        ['Donor/Provenance', 'donor']
      ])
    end
  end

  describe '#advanced_search_sort_opts' do
    let(:query_params) { { controller: 'catalog', action: 'index' } }
    let(:config) { CatalogController.blacklight_config }
    let(:search_state) { Blacklight::SearchState.new(query_params, config, CatalogController) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
        allow(helper).to receive(:blacklight_configuration_context).and_return(Blacklight::Configuration::Context.new(CatalogController))
        allow(helper).to receive(:search_state).and_return(search_state)
      end
    end

    it 'returns advanced search sort options from blacklight config' do
      expect(helper.advanced_search_sort_opts).to eq([
        ['relevance', 'score desc, pub_date_sort desc, title_sort asc'],
        ['year descending', 'pub_date_sort desc, title_sort asc'],
        ['year ascending', 'pub_date_sort asc, title_sort asc'],
        ['author A-Z', 'author_sort asc, title_sort asc'],
        ['author Z-A', 'author_sort desc, title_sort asc'],
        ['title A-Z', 'title_sort asc, pub_date_sort desc'],
        ['title Z-A', 'title_sort desc, pub_date_sort desc'],
        ['call number', 'callnum_sort asc, pub_date_sort desc']
      ])
    end
  end

  describe '#prep_query' do
    it 'strips leading and trailing whitespace and sanitizes query' do
      expect(helper.prep_query("  hi \"some\" +wacky <body> text&stuff's  ")).to eq("hi \"some\" +wacky  text&amp;stuff's")
    end

    it 'does not strip quotes if query is quoted' do
      expect(helper.prep_query('"hello"')).to eq('"hello"')
      expect(helper.prep_query("'hello'")).to eq("'hello'")
      expect(helper.prep_query('"hello world"')).to eq('"hello world"')
      expect(helper.prep_query("'hello world'")).to eq("'hello world'")
    end
  end

  describe '#params_to_form_values' do
    let(:params) {
      {
        q_row: ['Severus', 'Lily', 'Boyface Killah', 'English Breakfast'],
        op_row: ['AND', 'OR', 'begins_with', 'phrase'],
        boolean_row: { '1' => 'OR', '2' => 'AND', '3' => 'NOT' },
        search_field_row: ['author', 'title', 'subject', 'series'],
        controller: 'advanced_search',
        action: 'edit',
        advanced_query: 'yes',
      }
    }

    context 'valid params' do
      it 'returns an array of hashes' do
        expect(helper.params_to_form_values(params)).to eq([
          { q: 'Severus', op: 'AND', search_field: 'author' },
          { q: 'Lily', op: 'OR', search_field: 'title', boolean: 'OR' },
          { q: 'Boyface Killah', op: 'begins_with', search_field: 'subject', boolean: 'AND' },
          { q: 'English Breakfast', op: 'phrase', search_field: 'series', boolean: 'NOT' }
        ])
      end

      context 'queries with apostrophes' do
        let(:params) {
          {
            q_row: ["The O'Brien's House"],
            op_row: ['AND'],
            boolean_row: { '1' => 'OR' },
            search_field_row: ['title'],
            controller: 'advanced_search',
            action: 'edit',
            advanced_query: 'yes',
          }
        }
  
        it 'query with apostrophes includes the full string after the apostrophes' do
          expect(helper.params_to_form_values(params)).to eq([{ q: "The O'Brien's House", op: 'AND', search_field: 'title' }])
        end
      end
    end

    context 'wrong number of params' do
      context 'missing booleans' do
        let(:params_missing_bools) { params.merge(boolean_row: {}) }

        it 'fills in missing booleans with "AND"' do
          expect(helper.params_to_form_values(params_missing_bools)).to eq([
            { q: 'Severus', op: 'AND', search_field: 'author' },
            { q: 'Lily', op: 'OR', search_field: 'title', boolean: 'AND' },
            { q: 'Boyface Killah', op: 'begins_with', search_field: 'subject', boolean: 'AND' },
            { q: 'English Breakfast', op: 'phrase', search_field: 'series', boolean: 'AND' }
          ])
        end
      end

      context 'missing ops' do
        # Only 3 ops instead of 4
        let(:params_missing_ops) { params.merge(op_row: ['AND', 'OR', 'begins_with']) }

        it 'fills in missing ops with "AND"' do
          expect(helper.params_to_form_values(params_missing_ops)).to eq([
            { q: 'Severus', op: 'AND', search_field: 'author' },
            { q: 'Lily', op: 'OR', search_field: 'title', boolean: 'OR' },
            { q: 'Boyface Killah', op: 'begins_with', search_field: 'subject', boolean: 'AND' },
            { q: 'English Breakfast', op: 'AND', search_field: 'series', boolean: 'NOT' }
          ])
        end
      end

      context 'missing search_fields' do
        # 3 search_fields instead of 4
        let(:params_missing_search_fields) { params.merge(search_field_row: ['author', 'subject', 'series']) }

        it 'fills in missing search_fields with "all_fields"' do
          expect(helper.params_to_form_values(params_missing_search_fields)).to eq([
            { q: 'Severus', op: 'AND', search_field: 'author' },
            { q: 'Lily', op: 'OR', search_field: 'subject', boolean: 'OR' },
            { q: 'Boyface Killah', op: 'begins_with', search_field: 'series', boolean: 'AND' },
            { q: 'English Breakfast', op: 'phrase', search_field: 'all_fields', boolean: 'NOT' }
          ])
        end
      end

      context 'extra search_fields' do
        # 5 search_fields instead of 4
        let(:params_extra_search_fields) { params.merge(search_field_row: ['author', 'title', 'subject', 'series', 'donor']) }

        it 'ignores extra search_fields' do
          expect(helper.params_to_form_values(params_extra_search_fields)).to eq([
            { q: 'Severus', op: 'AND', search_field: 'author' },
            { q: 'Lily', op: 'OR', search_field: 'title', boolean: 'OR' },
            { q: 'Boyface Killah', op: 'begins_with', search_field: 'subject', boolean: 'AND' },
            { q: 'English Breakfast', op: 'phrase', search_field: 'series', boolean: 'NOT' }
          ])
        end
      end
    end
  end

  describe '#params_to_hidden_form_values' do
    context 'no f param' do
      let(:params) { ActionController::Parameters.new({}) }

      it 'returns an empty array' do
        expect(helper.params_to_hidden_form_values(params)).to be_empty
      end
    end

    context 'f param present' do
      let(:params) { ActionController::Parameters.new({ f: { author_facet: ['Bohlin, Sally', 'Riera Ojeda, Oscar'], format: ['Book'] } }) }

      it 'returns an array with values for a hidden form field' do
        expect(helper.params_to_hidden_form_values(params)).to eq([
          { name: 'f[author_facet][]', value: 'Bohlin, Sally' },
          { name: 'f[author_facet][]', value: 'Riera Ojeda, Oscar' },
          { name: 'f[format][]', value: 'Book' }
        ])
      end
    end
  end
end
