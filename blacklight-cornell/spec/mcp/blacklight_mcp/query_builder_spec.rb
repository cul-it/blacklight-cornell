# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::QueryBuilder do

  let(:relevance) { 'score desc, pub_date_sort desc, title_sort asc' }

  describe '.simple' do
    it 'builds the params the basic search form submits' do
      expect(described_class.simple(query: 'batman'))
        .to eq(q: 'batman', search_field: 'all_fields', page: 1, per_page: 20)
    end

    it 'defaults to all_fields and trims the query' do
      expect(described_class.simple(query: '  batman  ')[:q]).to eq('batman')
    end

    it 'accepts an empty query, which browses by filter alone' do
      params = described_class.simple(formats: ['Book'])
      expect(params[:q]).to eq('')
      expect(params[:f_inclusive]).to eq('format' => ['Book'])
    end

    describe 'search_field' do
      it 'accepts any configured search field' do
        expect(described_class.simple(query: 'nature', search_field: 'journaltitle')[:search_field])
          .to eq('journaltitle')
      end

      it 'rejects an unconfigured search field and names the valid ones' do
        expect { described_class.simple(query: 'x', search_field: 'summary') }
          .to raise_error(BlacklightMcp::InvalidArgument, /not a configured search field.*all_fields/m)
      end

      it 'rejects the UI separator entries, which are not real fields' do
        expect { described_class.simple(query: 'x', search_field: 'separator_1') }
          .to raise_error(BlacklightMcp::InvalidArgument)
      end
    end
  end

  describe '.advanced' do
    it 'builds the params the /advanced form submits' do
      params = described_class.advanced(
        rows: [{ query: 'batman' }, { query: 'Robin', field: 'journaltitle', op: 'phrase' }],
        booleans: ['NOT']
      )

      expect(params).to include(
        advanced_query: 'yes',
        search_field: 'advanced',
        q: '',
        q_row: %w[batman Robin],
        op_row: %w[AND phrase],
        search_field_row: %w[all_fields journaltitle],
        boolean_row: { '1' => 'NOT' }
      )
    end

    it 'numbers boolean_row from 1, joining each row to the one before it' do
      params = described_class.advanced(
        rows: [{ query: 'a' }, { query: 'b' }, { query: 'c' }, { query: 'd' }],
        booleans: %w[AND OR NOT]
      )

      expect(params[:boolean_row]).to eq('1' => 'AND', '2' => 'OR', '3' => 'NOT')
    end

    it 'defaults every join to AND when booleans are omitted' do
      params = described_class.advanced(rows: [{ query: 'a' }, { query: 'b' }, { query: 'c' }])
      expect(params[:boolean_row]).to eq('1' => 'AND', '2' => 'AND')
    end

    it 'needs no boolean for a single row' do
      params = described_class.advanced(rows: [{ query: 'a' }])
      expect(params[:boolean_row]).to eq({})
    end

    it 'accepts every operator the advanced form offers' do
      params = described_class.advanced(
        rows: [{ query: 'a', op: 'AND' }, { query: 'b', op: 'OR' },
               { query: 'c', op: 'phrase' }, { query: 'd', op: 'begins_with' }]
      )

      expect(params[:op_row]).to eq(%w[AND OR phrase begins_with])
    end

    it 'accepts every boolean the advanced form offers' do
      %w[AND OR NOT].each do |boolean|
        params = described_class.advanced(rows: [{ query: 'a' }, { query: 'b' }], booleans: [boolean])
        expect(params[:boolean_row]).to eq('1' => boolean)
      end
    end

    it 'upcases and trims a boolean' do
      params = described_class.advanced(rows: [{ query: 'a' }, { query: 'b' }], booleans: [' or '])
      expect(params[:boolean_row]).to eq('1' => 'OR')
    end

    describe 'validation' do
      it 'requires at least one row' do
        expect { described_class.advanced(rows: []) }
          .to raise_error(BlacklightMcp::InvalidArgument, /non-empty array/)
        expect { described_class.advanced({}) }
          .to raise_error(BlacklightMcp::InvalidArgument, /non-empty array/)
      end

      it 'rejects a blank row rather than silently dropping it' do
        expect { described_class.advanced(rows: [{ query: 'a' }, { query: '  ' }]) }
          .to raise_error(BlacklightMcp::InvalidArgument, /rows\[1\]\.query is required/)
      end

      it 'rejects more rows than the form allows' do
        rows = Array.new(described_class::MAX_ADVANCED_ROWS + 1) { { query: 'a' } }
        expect { described_class.advanced(rows: rows) }
          .to raise_error(BlacklightMcp::InvalidArgument, /at most #{described_class::MAX_ADVANCED_ROWS} rows/)
      end

      it 'requires exactly one fewer boolean than rows' do
        expect { described_class.advanced(rows: [{ query: 'a' }, { query: 'b' }], booleans: %w[AND OR]) }
          .to raise_error(BlacklightMcp::InvalidArgument, /expected 1 for 2 row\(s\), got 2/)
      end

      it 'rejects an unknown boolean' do
        expect { described_class.advanced(rows: [{ query: 'a' }, { query: 'b' }], booleans: ['XOR']) }
          .to raise_error(BlacklightMcp::InvalidArgument, /must be one of AND, OR, NOT/)
      end

      it 'rejects an unknown row operator' do
        expect { described_class.advanced(rows: [{ query: 'a', op: 'ends_with' }]) }
          .to raise_error(BlacklightMcp::InvalidArgument, /rows\[0\]\.op must be one of AND, OR, phrase, begins_with/)
      end

      it 'rejects an unknown per-row search field' do
        expect { described_class.advanced(rows: [{ query: 'a', field: 'nope' }]) }
          .to raise_error(BlacklightMcp::InvalidArgument, /rows\[0\]\.field "nope" is not a configured search field/)
      end
    end
  end

  describe 'facet filters' do
    it 'OR-s several values for one field through f_inclusive' do
      params = described_class.simple(query: 'x', filters: { 'format' => %w[Book Video] })
      expect(params[:f_inclusive]).to eq('format' => %w[Book Video])
      expect(params).not_to have_key(:f)
    end

    it 'AND-s values through f when filters_all is used' do
      params = described_class.simple(query: 'x', filters_all: { 'format' => %w[Book Microform] })
      expect(params[:f]).to eq('format' => %w[Book Microform])
      expect(params).not_to have_key(:f_inclusive)
    end

    it 'combines inclusive and conjunctive filters on different fields' do
      params = described_class.simple(query: 'x',
                                      filters: { 'format' => ['Book'] },
                                      filters_all: { 'language_facet' => ['English'] })
      expect(params[:f_inclusive]).to eq('format' => ['Book'])
      expect(params[:f]).to eq('language_facet' => ['English'])
    end

    it 'refuses the same field in both filters and filters_all' do
      expect {
        described_class.simple(query: 'x', filters: { 'format' => ['Book'] }, filters_all: { 'format' => ['Video'] })
      }.to raise_error(BlacklightMcp::InvalidArgument, /format appears in both filters and filters_all/)
    end

    it 'accepts every configured facet field' do
      BlacklightMcp::CatalogOptions.filterable_facet_field_keys.each do |field|
        params = described_class.simple(query: 'x', filters: { field => ['a value'] })
        expect(params[:f_inclusive]).to eq(field => ['a value'])
      end
    end

    it 'rejects a facet field the catalog does not have' do
      expect { described_class.simple(query: 'x', filters: { 'genre_facet' => ['Comedy'] }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /unknown facet field "genre_facet"/)
    end

    it 'rejects an internal facet hidden from students' do
      expect { described_class.simple(query: 'x', filters: { 'availability_facet' => ['Available'] }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /unknown facet field "availability_facet"/)
    end

    it 'sends a range facet to date_range rather than accepting it as a filter' do
      expect { described_class.simple(query: 'x', filters: { 'pub_date_facet' => ['1999'] }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /range facet; filter it with date_range/)
    end

    it 'rejects a filter with no usable values' do
      expect { described_class.simple(query: 'x', filters: { 'format' => ['', '  '] }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /at least one non-blank value/)
    end

    it 'rejects filters that are not an object of field => values' do
      expect { described_class.simple(query: 'x', filters: ['format']) }
        .to raise_error(BlacklightMcp::InvalidArgument, /must be an object of facet field/)
    end

    describe 'the formats and languages shortcuts' do
      it 'maps formats onto the format facet' do
        params = described_class.simple(query: 'x', formats: ['Book', 'Journal/Periodical'])
        expect(params[:f_inclusive]).to eq('format' => ['Book', 'Journal/Periodical'])
      end

      it 'maps languages onto the language_facet facet' do
        params = described_class.simple(query: 'x', languages: %w[English German])
        expect(params[:f_inclusive]).to eq('language_facet' => %w[English German])
      end

      it 'merges with an explicit filters entry for the same field' do
        params = described_class.simple(query: 'x', formats: ['Book'], filters: { 'format' => ['Video'] })
        expect(params[:f_inclusive]).to eq('format' => %w[Video Book])
      end

      it 'is ignored when empty' do
        expect(described_class.simple(query: 'x', formats: [], languages: [])).not_to have_key(:f_inclusive)
      end
    end
  end

  describe 'date and other ranges' do
    it 'builds range[pub_date_facet][begin]/[end] from date_range' do
      params = described_class.simple(query: 'x', date_range: { begin: 1966, end: 2025 })
      expect(params[:range]).to eq('pub_date_facet' => { 'begin' => '1966', 'end' => '2025' })
    end

    it 'accepts years as strings' do
      params = described_class.simple(query: 'x', date_range: { 'begin' => '1966', 'end' => '2025' })
      expect(params[:range]).to eq('pub_date_facet' => { 'begin' => '1966', 'end' => '2025' })
    end

    it 'accepts an equal begin and end' do
      params = described_class.simple(query: 'x', date_range: { begin: 2020, end: 2020 })
      expect(params[:range]).to eq('pub_date_facet' => { 'begin' => '2020', 'end' => '2020' })
    end

    it 'names any configured range facet through ranges' do
      params = described_class.simple(query: 'x', ranges: { 'pub_date_facet' => { begin: 1900, end: 1950 } })
      expect(params[:range]).to eq('pub_date_facet' => { 'begin' => '1900', 'end' => '1950' })
    end

    it 'requires both bounds, because the catalog ignores a half-open range' do
      expect { described_class.simple(query: 'x', date_range: { begin: 1966 }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /ranges\[pub_date_facet\]\.end is required/)
      expect { described_class.simple(query: 'x', date_range: { end: 2025 }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /ranges\[pub_date_facet\]\.begin is required/)
    end

    it 'rejects a reversed range, which the catalog treats as an error' do
      expect { described_class.simple(query: 'x', date_range: { begin: 2025, end: 1966 }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /begin \(2025\) must not be later than end \(1966\)/)
    end

    it 'rejects a non-numeric year' do
      expect { described_class.simple(query: 'x', date_range: { begin: 'nineteen sixty six', end: 2025 }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /must be a whole year/)
    end

    it 'rejects a range on a facet that is not configured as a range' do
      expect { described_class.simple(query: 'x', ranges: { 'format' => { begin: 1, end: 2 } }) }
        .to raise_error(BlacklightMcp::InvalidArgument, /"format" is not a range facet/)
    end

    it 'refuses the same field in both date_range and ranges' do
      expect {
        described_class.simple(query: 'x',
                               date_range: { begin: 1900, end: 1950 },
                               ranges: { 'pub_date_facet' => { begin: 1960, end: 1970 } })
      }.to raise_error(BlacklightMcp::InvalidArgument, /appears in both date_range and ranges/)
    end
  end

  describe 'sort' do
    it 'accepts a sort key verbatim' do
      expect(described_class.simple(query: 'x', sort: relevance)[:sort]).to eq(relevance)
    end

    it 'resolves a sort label to its key' do
      expect(described_class.simple(query: 'x', sort: 'year descending')[:sort])
        .to eq('pub_date_sort desc, title_sort asc')
    end

    it 'accepts every configured sort, by key and by label' do
      BlacklightMcp::CatalogOptions.sort_options.each do |option|
        expect(described_class.simple(query: 'x', sort: option['sort'])[:sort]).to eq(option['sort'])
        expect(described_class.simple(query: 'x', sort: option['label'])[:sort]).to eq(option['sort'])
      end
    end

    it 'omits sort entirely when none is given, leaving the catalog default in place' do
      expect(described_class.simple(query: 'x')).not_to have_key(:sort)
    end

    it 'rejects an unconfigured sort and lists the real ones' do
      expect { described_class.simple(query: 'x', sort: 'popularity') }
        .to raise_error(BlacklightMcp::InvalidArgument, /not a configured sort.*relevance/m)
    end

    it 'applies to advanced search too' do
      params = described_class.advanced(rows: [{ query: 'a' }], sort: 'title A-Z')
      expect(params[:sort]).to eq('title_sort asc, pub_date_sort desc')
    end
  end

  describe 'paging' do
    it 'defaults to page 1 and the catalog page size' do
      params = described_class.simple(query: 'x')
      expect(params[:page]).to eq(1)
      expect(params[:per_page]).to eq(described_class::DEFAULT_PER_PAGE)
    end

    it 'accepts a page and per_page' do
      params = described_class.simple(query: 'x', page: 3, per_page: 50)
      expect(params[:page]).to eq(3)
      expect(params[:per_page]).to eq(50)
    end

    it 'rejects a page below 1' do
      expect { described_class.simple(query: 'x', page: 0) }
        .to raise_error(BlacklightMcp::InvalidArgument, /page must be 1 or greater/)
    end

    it 'caps per_page' do
      expect { described_class.simple(query: 'x', per_page: described_class::MAX_PER_PAGE + 1) }
        .to raise_error(BlacklightMcp::InvalidArgument, /per_page must be between 1 and #{described_class::MAX_PER_PAGE}/)
    end

    it 'rejects a non-numeric page' do
      expect { described_class.simple(query: 'x', page: 'two') }
        .to raise_error(BlacklightMcp::InvalidArgument, /page must be a whole number/)
    end
  end

  describe 'argument hygiene' do
    it 'accepts string keys as well as symbols' do
      params = described_class.simple('query' => 'batman', 'search_field' => 'title')
      expect(params).to include(q: 'batman', search_field: 'title')
    end

    it 'rejects an over-long query rather than passing it to Solr' do
      expect { described_class.simple(query: 'a' * (described_class::MAX_QUERY_LENGTH + 1)) }
        .to raise_error(BlacklightMcp::InvalidArgument, /characters or fewer/)
    end

    it 'leaves query strings mutable, because SearchBuilder#clean_q edits them in place' do
      params = described_class.advanced(rows: [{ query: 'batman' }])
      expect(params[:q_row].first).not_to be_frozen
    end
  end
end
