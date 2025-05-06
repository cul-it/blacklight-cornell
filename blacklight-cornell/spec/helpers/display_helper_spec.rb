require 'rails_helper'

RSpec.describe DisplayHelper, type: :helper do
  describe '#render_display_link' do
    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
        allow(helper).to receive(:process_online_title).and_return('Processed Title')
      end
    end

    context 'when links are provided in args[:value]' do
      let(:args) { { field: 'url_findingaid_display', value: ['http://example.com|Example'] } }

      it 'renders the display link' do
        result = helper.render_display_link(args)
        expect(result.first).to include('Processed Title')
        expect(result.first).to include('http://example.com')
      end
    end

    context 'when links are fetched from args[:document]' do
      let(:document) { { 'url_findingaid_display' => ['http://example.com|Example'] } }
      let(:args) { { field: 'url_findingaid_display', document: document } }

      it 'renders the display link' do
        result = helper.render_display_link(args)
        expect(result.first).to include('Processed Title')
        expect(result.first).to include('http://example.com')
      end
    end

    context 'when render_format is raw' do
      let(:args) { { field: 'url_findingaid_display', value: ['http://example.com|Example'], format: 'raw' } }

      it 'returns the raw value' do
        result = helper.render_display_link(args)
        expect(result).to be_an(Array)
        expect(result.first).to include('Processed Title')
        expect(result.first).to include('http://example.com')
      end
    end

    context 'when field is url_findingaid_display' do
      let(:args) { { field: 'url_findingaid_display', value: ['http://example.com|Example', 'http://example2.com|Example2'] } }

      it 'returns all the values' do
        result = helper.render_display_link(args)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to include('Processed Title')
        expect(result.first).to include('http://example.com')
        expect(result.last).to include('http://example2.com')
      end
    end

    context 'when field is url_bookplate_display' do
      let(:args) { { field: 'url_bookplate_display', value: ['http://example.com|Example', 'http://example2.com|Example2'] } }

      it 'returns unique values joined by commas' do
        result = helper.render_display_link(args)
        expect(result).to include('Processed Title')
        expect(result).to include('http://example.com')
        expect(result).to include('http://example2.com')
        expect(result).to include(',')
      end
    end

    context 'when field is url_other_display' do
      let(:args) { { field: 'url_other_display', value: ['http://example.com|Example', 'http://example2.com|Example2'] } }

      it 'returns values joined by <br/>' do
        result = helper.render_display_link(args)
        expect(result).to include('Processed Title')
        expect(result).to include('http://example.com')
        expect(result).to include('http://example2.com')
        expect(result).to include('<br/>')
      end
    end
  end

  describe '#parseHistoryShowString' do
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:all_fields_config) { blacklight_config.default_search_field}

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
        allow(helper).to receive(:search_field_def_for_key).and_return(all_fields_config)
        allow(helper).to receive(:default_search_field).and_return(all_fields_config)
        allow(helper).to receive(:search_action_path) { |*args| search_catalog_url *args }
        allow(controller).to receive(:search_state_class).and_return(BlacklightCornell::SearchState)
        allow(helper).to receive(:search_state).and_return(CatalogController.search_state_class.new(params, blacklight_config, helper))
      end
    end

    it 'returns expected html' do
      params = {
        advanced_query: 'yes',
        boolean_row: { '1' => 'AND' },
        f: { language_facet: 'Cebuano' },
        f_inclusive: { language_facet: ['English', 'French'] },
        op_row: ['AND', 'AND'],
        q_row: ['Canada', ''],
        search_field: 'advanced',
        search_field_row: ['all_fields', 'all_fields'],
        sort: 'score desc, pub_date_sort desc, title_sort asc',
        controller: 'catalog',
        action: 'index',
        only_path: true
      }
      link_html = helper.parseHistoryShowString(params)
      link_sans_html = strip_tags(link_html)
      expect(link_sans_html).to include('All Fields: Canada')
      expect(link_sans_html).to include('Language:Cebuano')
      expect(link_sans_html).to include('Language:English OR French')
    end
  end
end
