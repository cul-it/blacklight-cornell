# frozen_string_literal: true

require 'rails_helper'

# ==============================================================================
# Tests the Unapi Gem endpoint that's modified to work with Rails 7
# https://github.com/cul-it/blacklight-unapi/compare/master...BL7_RAILS7-upgrade
#
# Ensuring Zotero Chrome/Firefox Connector can communicate with Zotero App
# in the Catalog. Example URL to use with connection:
# https://catalog.library.cornell.edu/catalog/2949228
#
# Connector => https://www.zotero.org/download/connectors
# App => https://www.zotero.org/download/
# https://www.zotero.org/support/dev/exposing_metadata
# ----------------------------------------------------------------------------
RSpec.describe CatalogController, type: :controller do
  describe '#unapi' do
    let(:exported_body) { '<dc>export</dc>' }
    let(:export_formats) { { 'xml' => { content_type: 'text/xml' } } }
    let(:document) { instance_double(SolrDocument) }
    let(:search_service) { instance_double(Blacklight::SearchService) }

    before do
      allow(controller).to receive(:search_service).and_return(search_service)
      allow(search_service).to receive(:fetch).with('123').and_return([nil, document])
      allow(document).to receive(:export_formats).and_return(export_formats)
      allow(document).to receive(:exports_as?).and_return(false)
      allow(document).to receive(:exports_as?).with(:xml).and_return(true)
      allow(document).to receive(:export_as).with(:xml).and_return(exported_body)
    end

    it 'returns exported data for supported formats' do
      get :unapi, params: { id: '123', format: 'xml' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(exported_body)
      expect(response.headers['Content-Type']).to include('text/xml')
      expect(response.headers['Content-Disposition']).to include('inline')
    end

    it 'returns 406 for unsupported formats' do
      get :unapi, params: { id: '123', format: 'bogus' }

      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
