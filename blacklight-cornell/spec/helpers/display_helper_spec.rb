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
end
