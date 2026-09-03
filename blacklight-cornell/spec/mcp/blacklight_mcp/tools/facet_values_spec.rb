# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::FacetValues do
  let(:languages) { (1..25).map { |i| ["Language #{i}", 100 - i] } }

  it 'is read-only and requires a facet field' do
    expect(described_class.name_value).to eq('facet_values')
    expect(described_class.annotations.read_only_hint).to be true
    expect(described_class.input_schema.to_h[:required]).to eq(['field'])
  end

  it 'offers only facets that have discrete values' do
    enum = described_class.input_schema.to_h[:properties][:field][:enum]
    expect(enum).to include('format', 'language_facet', 'online', 'author_facet')
    expect(enum).not_to include('pub_date_facet')
    expect(enum).not_to include('availability_facet', 'collection', 'subject_topic_lc_facet')
  end

  describe '.call' do
    it 'returns the facet values with their counts' do
      stub_search_runner(facet_response: solr_response(facets: { 'language_facet' => [['English', 9], ['German', 4]] }))
      payload = tool_payload(described_class, field: 'language_facet')

      expect(payload).to include('facet_field' => 'language_facet', 'label' => 'Language', 'page' => 1)
      expect(payload['values']).to eq([{ 'value' => 'English', 'count' => 9 },
                                       { 'value' => 'German', 'count' => 4 }])
      expect(payload['has_more']).to be false
    end

    it 'scopes the counts by the same query and filters search accepts' do
      captured = stub_search_runner(facet_response: solr_response(facets: { 'language_facet' => [['English', 1]] }))
      tool_payload(described_class, field: 'language_facet', query: 'rome', formats: ['Book'],
                                    date_range: { begin: 1900, end: 2000 })

      expect(captured).to include(q: 'rome', f_inclusive: { 'format' => ['Book'] })
      expect(captured[:range]).to eq('pub_date_facet' => { 'begin' => '1900', 'end' => '2000' })
    end

    it 'passes facet paging, prefix and ordering through to Blacklight' do
      captured = stub_search_runner(facet_response: solr_response(facets: { 'format' => [['Book', 1]] }))
      tool_payload(described_class, field: 'format', page: 2, prefix: 'B', sort: 'index')

      expect(captured[:'facet.page']).to eq(2)
      expect(captured[:'facet.prefix']).to eq('B')
      expect(captured[:'facet.sort']).to eq('index')
    end

    it 'does not mistake the facet ordering for a result sort' do
      captured = stub_search_runner(facet_response: solr_response(facets: { 'format' => [['Book', 1]] }))
      tool_payload(described_class, field: 'format', sort: 'index')

      expect(captured).not_to have_key(:sort)
    end

    it 'trims the sentinel value Blacklight fetches to detect a further page' do
      stub_search_runner(facet_response: solr_response(facets: { 'language_facet' => languages }))
      payload = tool_payload(described_class, field: 'language_facet')

      limit = payload['per_page']
      expect(payload['values'].size).to eq(limit)
      expect(payload['has_more']).to be true
    end

    it 'rejects an unknown facet field' do
      stub_search_runner
      expect(tool_error(described_class, field: 'nope')).to match(/not a configured facet field/)
    end

    it 'points a range facet at date_range instead' do
      stub_search_runner
      expect(tool_error(described_class, field: 'pub_date_facet')).to match(/range facet and has no discrete values/)
    end

    # Facet paging becomes a Solr facet.offset, walked the same way a deep
    # result page is, so it gets the same window.
    it 'refuses to page past the result window' do
      stub_search_runner
      window = BlacklightMcp::QueryBuilder::MAX_RESULT_WINDOW

      expect(tool_error(described_class, field: 'author_facet', page: window))
        .to match(/past this catalog's #{window}-value limit/)
    end

    it 'allows a page that stays inside the window' do
      captured = stub_search_runner(facet_response: solr_response(facets: { 'format' => %w[Book 10] }))
      tool_payload(described_class, field: 'format', page: 2)

      expect(captured[:'facet.page']).to eq(2)
    end

    it 'rejects a non-numeric page' do
      stub_search_runner
      expect(tool_error(described_class, field: 'format', page: 'two')).to match(/page must be a whole number/)
    end
  end
end
