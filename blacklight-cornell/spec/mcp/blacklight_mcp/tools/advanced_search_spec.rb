# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::AdvancedSearch do
  describe 'the tool declaration' do
    it 'is named advanced_search and is advertised as read-only' do
      expect(described_class.name_value).to eq('advanced_search')
      expect(described_class.annotations.read_only_hint).to be true
    end

    it 'requires rows' do
      expect(described_class.input_schema.to_h[:required]).to eq(['rows'])
    end

    it 'offers every row operator the advanced form offers' do
      row_schema = described_class.input_schema.to_h[:properties][:rows][:items]
      expect(row_schema[:properties][:op][:enum]).to eq(%w[AND OR phrase begins_with])
    end

    it 'offers every boolean the advanced form offers' do
      booleans = described_class.input_schema.to_h[:properties][:booleans][:items]
      expect(booleans[:enum]).to eq(%w[AND OR NOT])
    end

    it 'caps the number of rows' do
      expect(described_class.input_schema.to_h[:properties][:rows][:maxItems])
        .to eq(BlacklightMcp::QueryBuilder::MAX_ADVANCED_ROWS)
    end

    it 'accepts the same facet, range and sort arguments as search' do
      properties = described_class.input_schema.to_h[:properties].keys
      expect(properties).to include(:rows, :booleans, :formats, :languages, :filters, :filters_all,
                                    :date_range, :ranges, :sort, :page, :per_page)
    end
  end

  describe '.call' do
    it 'submits the advanced form params the catalog expects' do
      captured = stub_search_runner
      tool_payload(described_class,
                   rows: [{ query: 'batman' }, { query: 'Robin', field: 'journaltitle', op: 'OR' }],
                   booleans: ['NOT'])

      expect(captured).to include(
        advanced_query: 'yes',
        search_field: 'advanced',
        q_row: %w[batman Robin],
        op_row: %w[AND OR],
        search_field_row: %w[all_fields journaltitle],
        boolean_row: { '1' => 'NOT' }
      )
    end

    it 'carries facets, date range and sort alongside the rows' do
      captured = stub_search_runner
      tool_payload(described_class,
                   rows: [{ query: 'batman' }],
                   formats: ['Book', 'Journal/Periodical'],
                   languages: %w[English German],
                   date_range: { begin: 1966, end: 2025 },
                   sort: 'relevance')

      expect(captured[:f_inclusive]).to eq('format' => ['Book', 'Journal/Periodical'],
                                           'language_facet' => %w[English German])
      expect(captured[:range]).to eq('pub_date_facet' => { 'begin' => '1966', 'end' => '2025' })
      expect(captured[:sort]).to eq('score desc, pub_date_sort desc, title_sort asc')
    end

    it 'echoes the rows and their joining booleans back in the result' do
      stub_search_runner
      payload = tool_payload(described_class,
                             rows: [{ query: 'batman' }, { query: 'Robin' }],
                             booleans: ['OR'])

      expect(payload['search']['rows'].last['joined_to_previous_by']).to eq('OR')
    end

    describe 'invalid arguments' do
      before { stub_search_runner }

      it 'reports a boolean count that does not match the rows' do
        expect(tool_error(described_class, rows: [{ query: 'a' }, { query: 'b' }], booleans: %w[AND AND]))
          .to match(/exactly one fewer entry than rows/)
      end

      it 'reports a blank row' do
        expect(tool_error(described_class, rows: [{ query: '' }]))
          .to match(/rows\[0\]\.query is required/)
      end

      it 'reports missing rows' do
        expect(tool_error(described_class, {})).to match(/non-empty array/)
      end
    end
  end
end
