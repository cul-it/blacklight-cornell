# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::SearchRunner do
  describe '#documents' do
    # Fetching many records goes through Blacklight's *search* path, which
    # returns only the fields the results page displays. Holdings and item data
    # are show-page fields: without fl:'*' they are absent, check_availability
    # quietly falls back to the coarse availability summary, and nothing errors.
    # This regression is invisible except by reading a real payload.
    it "asks Solr for every field, not just the ones the results page shows" do
      service = instance_double(Blacklight::SearchService)
      runner = described_class.new({})
      allow(runner).to receive(:search_service).and_return(service)

      expect(service).to receive(:fetch).with(%w[1 2], fl: '*').and_return([])

      runner.documents(%w[1 2])
    end

    it 'trims the ids it is given' do
      service = instance_double(Blacklight::SearchService)
      runner = described_class.new({})
      allow(runner).to receive(:search_service).and_return(service)

      expect(service).to receive(:fetch).with(%w[7], fl: '*').and_return([])

      runner.documents(['  7 '])
    end
  end

  describe 'Solr timeouts' do
    # Shorter than the website's on purpose: an MCP client retries, and a slow
    # query holding a Puma thread is how MCP traffic starves the catalog.
    it 'gives MCP its own connection settings without touching the catalog\'s' do
      connection = described_class.blacklight_config.connection_config

      expect(connection[:timeout]).to eq(described_class::SOLR_TIMEOUT)
      expect(connection[:open_timeout]).to eq(described_class::SOLR_OPEN_TIMEOUT)
      expect(connection[:retry_503]).to be(false)
      expect(CatalogController.blacklight_config.connection_config).not_to have_key(:timeout)
    end
  end
end
