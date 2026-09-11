# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp do
  # Links are for a reader to open, so they name the catalog rather than
  # whatever host answered the call. That host can be localhost, an integration
  # box, or -- if this endpoint ever moves to a domain of its own -- somewhere
  # that serves no record pages at all.
  describe '.catalog_url' do
    def catalog(value)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MCP_CATALOG_URL', described_class::CATALOG_URL).and_return(value)
    end

    it 'is the public catalog unless told otherwise' do
      expect(described_class.catalog_url).to eq('https://catalog.library.cornell.edu')
    end

    it 'can be pointed at another catalog' do
      catalog('https://catalog-int.library.cornell.edu')

      expect(described_class.catalog_url).to eq('https://catalog-int.library.cornell.edu')
    end

    # Callers join paths onto this, so a trailing slash would double up.
    it 'keeps no trailing slash' do
      catalog('https://catalog-int.library.cornell.edu/')

      expect(described_class.catalog_url).to eq('https://catalog-int.library.cornell.edu')
    end

    it 'falls back to the catalog when the variable is set to nothing' do
      catalog('   ')

      expect(described_class.catalog_url).to eq(described_class::CATALOG_URL)
    end
  end

  describe '.enabled?' do
    def mcp(value)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MCP', '').and_return(value)
    end

    it 'is on when nothing says otherwise' do
      expect(described_class).to be_enabled
    end

    it 'is off for MCP=false' do
      mcp('false')

      expect(described_class).not_to be_enabled
    end

    it 'ignores the case it is written in' do
      %w[FALSE False fAlSe].each do |value|
        mcp(value)

        expect(described_class).not_to be_enabled, "#{value.inspect} should turn it off"
      end
    end

    # Only the word false. A typo must not take the endpoint down, and neither
    # should someone assuming another spelling works.
    it 'stays on for anything that is not the word false' do
      ['', 'true', '0', 'no', 'off', 'maybe', 'falsey'].each do |value|
        mcp(value)

        expect(described_class).to be_enabled, "#{value.inspect} should leave it on"
      end
    end
  end
end
