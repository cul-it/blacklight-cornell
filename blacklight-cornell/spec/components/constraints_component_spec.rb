# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConstraintsComponent, type: :component do
  subject(:component) { described_class.new(search_state: search_state) }

  let(:rendered) { render_inline_to_capybara_node(component) }
  let(:search_state) { BlacklightCornell::SearchState.new(query_params.with_indifferent_access, controller.blacklight_config) }

  context 'with a simple query' do
    let(:query_params) { { q: 'some query' } }

    it 'renders a start-over link' do
      expect(rendered).to have_link 'Start over', href: '/catalog'
    end

    it 'has a header' do
      expect(rendered).to have_selector('h2', text: 'Search Constraints')
    end

    it 'wraps the output in a div' do
      expect(rendered).to have_selector('div#appliedParams')
    end

    it 'renders the query' do
      expect(rendered).to have_selector('.filter-value', text: 'some query')
    end
  end

  context 'with a facet' do
    let(:query_params) { { f: { lc_callnum_facet: ['some value'] } } }

    it 'renders the query' do
      expect(rendered).to have_selector('.selected-facets a .filter-label', text: 'Call Number').and(have_selector('.selected-facets a .filter-value', text: 'some value'))
    end
  end

  context 'with an advanced query' do
    let(:query_params) { advanced_query_params }

    before do
      allow(controller).to receive(:params).and_return(advanced_query_params)
    end

    context 'single query row' do
      let(:advanced_query_params) { { q_row: ['pickles'],
                                      op_row: ['AND'],
                                      search_field_row: ['title'],
                                      boolean_row: {} } }

      it 'renders the query' do
        expect(rendered).to have_link 'Title: pickles', href: '/catalog'
      end
    end

    context 'multiple query rows' do
      let(:advanced_query_params) { { q_row: ['pickles', 'cheese', 'toast'],
                                      op_row: ['AND', 'AND', 'begins_with'],
                                      search_field_row: ['title', 'all_fields', 'notes'],
                                      boolean_row: { '1' => 'OR', '2' => 'AND' },
                                      f: { 'format' => ['Book'], 'language_facet' => ['English', 'French'] },
                                      f_inclusive: { 'language_facet' => ['English', 'French'] } } }
      it 'renders the query' do
        expect(rendered.all('a[title="Remove"]').count).to eq(7)

        # First query constraint
        removed_query_params = advanced_query_params.deep_dup
        removed_query_params[:q_row].delete_at(0)
        removed_query_params[:op_row].delete_at(0)
        removed_query_params[:search_field_row].delete_at(0)
        removed_query_params[:boolean_row] = { '1' => 'AND' }
        expect(rendered).to have_link 'Title: pickles', href: component.helpers.search_catalog_path(removed_query_params)

        # Second query constraint
        removed_query_params = advanced_query_params.deep_dup
        removed_query_params[:q_row].delete_at(1)
        removed_query_params[:op_row].delete_at(1)
        removed_query_params[:search_field_row].delete_at(1)
        removed_query_params[:boolean_row] = { '1' => 'AND' }
        expect(rendered).to have_link 'OR All Fields: cheese', href: component.helpers.search_catalog_path(removed_query_params)

        # Third query constraint
        removed_query_params = advanced_query_params.deep_dup
        removed_query_params[:q_row].delete_at(2)
        removed_query_params[:op_row].delete_at(2)
        removed_query_params[:search_field_row].delete_at(2)
        removed_query_params[:boolean_row] = { '1' => 'OR' }
        expect(rendered).to have_link 'AND Notes: toast', href: component.helpers.search_catalog_path(removed_query_params)
        
        # Filter constraints from search results facets
        removed_f_format_param = advanced_query_params[:f].except('format')
        removed_facet_params = advanced_query_params.merge(f: removed_f_format_param, only_path: true)
        expect(rendered).to have_link 'Format: Book', href: "http://test.host/catalog?#{removed_facet_params.to_query}"
        removed_f_english_param = { 'format' => ['Book'], 'language_facet' => ['French'] }
        removed_facet_params = advanced_query_params.merge(f: removed_f_english_param, only_path: true)
        expect(rendered).to have_link 'Language: English', href: "http://test.host/catalog?#{removed_facet_params.to_query}"
        removed_f_french_param = { 'format' => ['Book'], 'language_facet' => ['English'] }
        removed_facet_params = advanced_query_params.merge(f: removed_f_french_param, only_path: true)
        expect(rendered).to have_link 'Language: French', href: "http://test.host/catalog?#{removed_facet_params.to_query}"

        # Filter constraint from advanced search form
        removed_advanced_facet_params = advanced_query_params.except(:f_inclusive).merge(only_path: true)
        expect(rendered).to have_link 'Language: English OR French', href: "http://test.host/catalog?#{removed_advanced_facet_params.to_query}"
      end
    end
  end
end
