# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::DescribeSearchOptions do

  before do
    stub_search_runner(
      response: solr_response(
        facets: { 'format' => [['Book', 100], ['Journal/Periodical', 50]],
                  'language_facet' => [['English', 90], ['German', 10]] },
        stats: { 'pub_date_facet' => { 'min' => 1500.0, 'max' => 2026.0 } }
      )
    )
  end

  it 'is read-only' do
    expect(described_class.name_value).to eq('describe_search_options')
    expect(described_class.annotations.read_only_hint).to be true
  end

  describe 'the reported options' do
    subject(:payload) { tool_payload(described_class, include_facet_values: false) }

    it 'lists every search field with its label and whether the advanced form offers it' do
      all_fields = payload['search_fields'].find { |f| f['search_field'] == 'all_fields' }
      expect(all_fields).to include('in_advanced_form' => true)
      expect(payload['search_fields'].map { |f| f['search_field'] })
        .to eq(BlacklightMcp::CatalogOptions.search_field_keys)
    end

    it 'lists the advanced-form search fields separately' do
      expect(payload['advanced_search_fields']).to include('all_fields', 'title', 'journaltitle', 'author')
      expect(payload['advanced_search_fields']).not_to include('author_browse')
    end

    it 'documents the row operators and booleans' do
      expect(payload['row_operators'].keys).to eq(%w[AND OR phrase begins_with])
      expect(payload['row_booleans']).to eq(%w[AND OR NOT])
    end

    it 'lists every sort with its key and label, and names the default' do
      expect(payload['sorts']).to include('sort' => 'score desc, pub_date_sort desc, title_sort asc',
                                          'label' => 'relevance')
      expect(payload['default_sort']).to eq(CatalogController.blacklight_config.default_sort_field.key)
    end

    it 'lists every facet, flagging range and query facets' do
      by_facet = payload['facet_fields'].index_by { |f| f['facet'] }

      expect(by_facet['Format']).to include('label' => 'Format', 'in_advanced_form' => true)
      expect(by_facet['Publication Year']).to include('type' => 'range')
      expect(by_facet['Date Acquired']).to include('type' => 'query')
      expect(by_facet['Date Acquired']['values']).to include('last_1_week', 'last_1_month', 'last_1_years')
    end

    it 'names facets the way the catalog does, not the way Solr does' do
      facets = payload['facet_fields'].map { |facet| facet['facet'] }

      expect(facets).to include('Library Location', 'Subject: Region', 'Call Number')
      expect(facets).not_to include('location', 'fast_geo_facet', 'lc_callnum_facet')
    end

    it 'does not advertise internal facets hidden from students' do
      facets = payload['facet_fields'].map { |facet| facet['facet'] }

      expect(facets).not_to include('availability_facet', 'collection', 'subject_topic_lc_facet')
    end

    it 'names the range facets and the advanced-form facets' do
      expect(payload['range_facet_fields']).to eq(['Publication Year'])
      expect(payload['advanced_facet_fields']).to eq(['Publication Year', 'Format', 'Language'])
    end
  end

  describe 'facet value sampling' do
    it 'samples the advanced-form facets by default' do
      payload = tool_payload(described_class)

      expect(payload['facet_values']['Format']['values'])
        .to eq([{ 'value' => 'Book', 'count' => 100 }, { 'value' => 'Journal/Periodical', 'count' => 50 }])
      expect(payload['facet_values']['Language']['values'].map { |v| v['value'] }).to eq(%w[English German])
      expect(payload['facet_values']['Publication Year']).to include('min' => 1500, 'max' => 2026)
    end

    it 'samples only the facets asked for' do
      payload = tool_payload(described_class, facet_fields: ['Format'])
      expect(payload['facet_values'].keys).to eq(['Format'])
    end

    it 'answers under the readable name even when asked by Solr field' do
      payload = tool_payload(described_class, facet_fields: ['format'])
      expect(payload['facet_values'].keys).to eq(['Format'])
    end

    it 'can be skipped' do
      expect(tool_payload(described_class, include_facet_values: false)).not_to have_key('facet_values')
    end

    it 'reports an unknown facet as a tool error' do
      expect(tool_error(described_class, facet_fields: ['not_a_facet'])).to match(/unknown facet\(s\)/)
    end
  end
end
