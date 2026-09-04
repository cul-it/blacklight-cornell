# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::ResultPresenter do
  let(:docs) do
    [
      { 'id' => '123', 'title_display' => 'Batman', 'author_display' => 'Kane, Bob',
        'format' => ['Book'], 'pub_date_display' => '1966', 'pub_info_display' => 'New York : DC, 1966.',
        'language_display' => ['English'], 'lc_callnum_display' => ['PN6728 .B36'],
        'edition_display' => 'First edition.' },
      { 'id' => '456', 'fulltitle_display' => 'Robin', 'format' => %w[Book Microform] }
    ]
  end

  let(:response) do
    solr_response(docs: docs, num_found: 41, rows: 2, start: 2,
                  facets: { 'format' => [['Book', 10], ['Video', 3]], 'language_facet' => [['English', 9]] },
                  stats: { 'pub_date_facet' => { 'min' => 1900.0, 'max' => 2020.0 } })
  end

  subject(:payload) { described_class.new(response, params: params, base_url: 'http://test.host').to_h }

  let(:params) { { q: 'batman', search_field: 'all_fields' } }

  describe 'paging' do
    it 'reports the total, page, page size and page count' do
      expect(payload).to include('total' => 41, 'page' => 2, 'per_page' => 2, 'total_pages' => 21)
    end
  end

  describe 'documents' do
    it 'summarizes each record with its citation fields' do
      expect(payload['documents'].first).to include(
        'id' => '123',
        'title' => 'Batman',
        'author' => 'Kane, Bob',
        'format' => 'Book',
        'publication_year' => '1966',
        'publication' => 'New York : DC, 1966.',
        'language' => 'English',
        'edition' => 'First edition.',
        'call_number' => 'PN6728 .B36'
      )
    end

    it 'links each record back to the catalog' do
      expect(payload['documents'].first).to include(
        'path' => '/catalog/123',
        'url' => 'http://test.host/catalog/123'
      )
    end

    it 'omits the absolute url when no base url is known' do
      payload = described_class.new(response, params: params).to_h
      expect(payload['documents'].first).not_to have_key('url')
      expect(payload['documents'].first['path']).to eq('/catalog/123')
    end

    it 'falls back through the alternative title fields' do
      expect(payload['documents'].last['title']).to eq('Robin')
    end

    it 'keeps genuinely multi-valued fields as arrays' do
      expect(payload['documents'].last['format']).to eq(%w[Book Microform])
    end

    it 'omits fields the record does not have' do
      expect(payload['documents'].last).not_to have_key('author')
    end
  end

  describe 'facets' do
    it 'returns each facet with its label, values and counts' do
      expect(payload['facets']['Format']).to eq(
        'label' => 'Format',
        'values' => [{ 'value' => 'Book', 'count' => 10 }, { 'value' => 'Video', 'count' => 3 }]
      )
    end

    it 'reports range facets as min/max bounds rather than values' do
      expect(payload['facets']['Publication Year']).to eq(
        'label' => 'Publication Year', 'type' => 'range', 'min' => 1900, 'max' => 2020
      )
    end

    it 'caps the values returned per facet' do
      many = solr_response(facets: { 'format' => (1..50).map { |i| ["Format #{i}", i] } })
      values = described_class.new(many, params: {}).to_h['facets']['Format']['values']
      expect(values.size).to eq(described_class::FACET_VALUE_LIMIT)
    end
  end

  describe 'the search summary' do
    it 'echoes a simple search back' do
      expect(payload['search']).to eq('query' => 'batman', 'search_field' => 'all_fields')
    end

    it 'echoes filters, ranges and sort' do
      params = { q: 'x', search_field: 'all_fields',
                 f_inclusive: { 'format' => ['Book'] },
                 f: { 'language_facet' => ['English'] },
                 range: { 'pub_date_facet' => { 'begin' => '1966', 'end' => '2025' } },
                 sort: 'title_sort asc, pub_date_sort desc' }

      summary = described_class.new(response, params: params).to_h['search']

      expect(summary['filters']).to eq('format' => ['Book'])
      expect(summary['filters_all']).to eq('language_facet' => ['English'])
      expect(summary['ranges']).to eq('pub_date_facet' => { 'begin' => '1966', 'end' => '2025' })
      expect(summary['sort']).to eq('title_sort asc, pub_date_sort desc')
    end

    it 'spells out an advanced search row by row, including the joining booleans' do
      params = BlacklightMcp::QueryBuilder.advanced(
        rows: [{ query: 'batman' }, { query: 'Robin', field: 'title', op: 'phrase' }],
        booleans: ['NOT']
      )

      rows = described_class.new(response, params: params).to_h['search']['rows']

      expect(rows).to eq([
                           { 'query' => 'batman', 'field' => 'all_fields', 'op' => 'AND' },
                           { 'query' => 'Robin', 'field' => 'title', 'op' => 'phrase',
                             'joined_to_previous_by' => 'NOT' }
                         ])
    end
  end

  describe '.document' do
    it 'summarizes a single record' do
      document = SolrDocument.new(docs.first)
      expect(described_class.document(document, base_url: 'http://test.host'))
        .to include('id' => '123', 'title' => 'Batman', 'url' => 'http://test.host/catalog/123')
    end
  end
end
