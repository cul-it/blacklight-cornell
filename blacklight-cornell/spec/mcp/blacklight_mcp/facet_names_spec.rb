# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::FacetNames do
  # Only this one variable is faked; everything else in ENV behaves normally.
  def solr_names(value)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MCP_SOLR_FACETS_DISPLAY', '').and_return(value)
  end

  describe 'by default' do
    it 'calls a facet what the catalog calls it' do
      expect(described_class.public_name('fast_geo_facet')).to eq('Subject: Region')
      expect(described_class.public_name('lc_callnum_facet')).to eq('Call Number')
      expect(described_class.public_name('subject_content_facet')).to eq('Fiction/Non-Fiction')
    end

    it 'advertises no Solr field names at all' do
      expect(described_class.public_names).to all(satisfy { |name| !name.end_with?('_facet') })
    end
  end

  describe 'MCP_SOLR_FACETS_DISPLAY' do
    it 'restores the Solr field names when on' do
      solr_names('true')
      expect(described_class.public_name('fast_geo_facet')).to eq('fast_geo_facet')
    end

    it 'accepts the usual ways of writing yes' do
      %w[1 true TRUE yes on].each do |value|
        solr_names(value)
        expect(described_class).to be_solr_names, "#{value.inspect} should turn it on"
      end
    end

    it 'stays off for anything else, including nonsense' do
      ['', 'false', '0', 'no', 'maybe'].each do |value|
        solr_names(value)
        expect(described_class).not_to be_solr_names, "#{value.inspect} should leave it off"
      end
    end
  end

  describe '.resolve' do
    it 'takes the readable name' do
      expect(described_class.resolve('Library Location')).to eq('location')
    end

    it 'ignores case, because an assistant will not match it exactly' do
      expect(described_class.resolve('library location')).to eq('location')
      expect(described_class.resolve('  LANGUAGE  ')).to eq('language_facet')
    end

    # Clients written against the old vocabulary must keep working.
    it 'still takes the Solr field' do
      expect(described_class.resolve('language_facet')).to eq('language_facet')
    end

    it 'returns nil for anything that is not a facet' do
      expect(described_class.resolve('genre_facet')).to be_nil
      expect(described_class.resolve('')).to be_nil
      expect(described_class.resolve(nil)).to be_nil
    end

    it 'refuses an internal facet by either name' do
      expect(described_class.resolve('availability_facet')).to be_nil
      expect(described_class.resolve('Availability')).to be_nil
    end

    it 'round-trips every facet it advertises' do
      described_class.public_names.each do |name|
        expect(described_class.resolve(name)).to be_present, "#{name} is advertised but cannot be resolved"
      end
    end
  end
end
