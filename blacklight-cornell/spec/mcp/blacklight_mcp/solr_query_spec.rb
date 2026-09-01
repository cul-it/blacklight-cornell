# frozen_string_literal: false
# The catalog's search code edits query strings in place, so this file must not
# freeze its strings. Same reason app/models/search_builder.rb doesn't.

require 'rails_helper'

# These run MCP-built parameters through the catalog's real search code and
# check the Solr query that comes out. Nothing is sent to Solr, so they cover the
# whole translation -- facets, date ranges, AND/OR/NOT, sorting, paging --
# without depending on what happens to be in the index.
RSpec.describe 'MCP params translated to Solr' do
  # A real URL from the catalog's advanced search form: four rows joined by
  # AND/OR/NOT, two formats, two languages, a date range and a sort.
  ADVANCED_FORM_QUERY_STRING = [
    'advanced_query=yes',
    'boolean_row%5B1%5D=AND&boolean_row%5B2%5D=OR&boolean_row%5B3%5D=NOT',
    'commit=Search',
    'f_inclusive%5Bformat%5D%5B%5D=Book&f_inclusive%5Bformat%5D%5B%5D=Journal%2FPeriodical',
    'f_inclusive%5Blanguage_facet%5D%5B%5D=English&f_inclusive%5Blanguage_facet%5D%5B%5D=German',
    'op_row%5B%5D=AND&op_row%5B%5D=OR&op_row%5B%5D=AND&op_row%5B%5D=AND',
    'q=',
    'q_row%5B%5D=batman&q_row%5B%5D=Robin&q_row%5B%5D=Spiderman&q_row%5B%5D=Pizza',
    'range%5Bpub_date_facet%5D%5Bbegin%5D=1966&range%5Bpub_date_facet%5D%5Bend%5D=2025',
    'search_field=advanced',
    'search_field_row%5B%5D=all_fields&search_field_row%5B%5D=journaltitle',
    'search_field_row%5B%5D=all_fields&search_field_row%5B%5D=title',
    'sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc'
  ].join('&').freeze

  # New parameters every time: the search code edits the strings it is given.
  def solr_params(params)
    BlacklightMcp::SearchRunner.new(params).solr_params.deep_stringify_keys
  end

  def browser_params
    Rack::Utils.parse_nested_query(ADVANCED_FORM_QUERY_STRING).except('commit')
  end

  describe 'the advanced search form, reproduced through the MCP tool' do
    let(:mcp_params) do
      BlacklightMcp::QueryBuilder.advanced(
        rows: [{ query: 'batman', field: 'all_fields', op: 'AND' },
               { query: 'Robin', field: 'journaltitle', op: 'OR' },
               { query: 'Spiderman', field: 'all_fields', op: 'AND' },
               { query: 'Pizza', field: 'title', op: 'AND' }],
        booleans: %w[AND OR NOT],
        formats: ['Book', 'Journal/Periodical'],
        languages: %w[English German],
        date_range: { begin: 1966, end: 2025 },
        sort: 'score desc, pub_date_sort desc, title_sort asc'
      )
    end

    it 'produces the same catalog params the browser submits' do
      expect(mcp_params.deep_stringify_keys.slice(*browser_params.keys)).to eq(browser_params)
    end

    it 'produces the same Solr q' do
      expect(solr_params(mcp_params)['q']).to eq(solr_params(browser_params)['q'])
    end

    it 'produces the same Solr filter queries' do
      expect(solr_params(mcp_params)['fq'].sort).to eq(solr_params(browser_params)['fq'].sort)
    end

    it 'produces the same Solr sort' do
      expect(solr_params(mcp_params)['sort']).to eq(solr_params(browser_params)['sort'])
    end
  end

  describe 'booleans between rows' do
    # An exact-phrase row on the title field produces a single piece of query,
    # so the only AND/OR/NOT left are the ones joining the rows.
    def q_for(booleans, terms = %w[alpha beta gamma])
      params = BlacklightMcp::QueryBuilder.advanced(
        rows: terms.map { |term| { query: term, field: 'title', op: 'phrase' } },
        booleans: booleans
      )
      solr_params(params)['q']
    end

    it 'nests rows left to right, so A op1 B op2 C reads ((A op1 B) op2 C)' do
      expect(q_for(%w[AND OR]))
        .to eq('(((title_quoted:"alpha") AND (title_quoted:"beta")) OR (title_quoted:"gamma"))')
    end

    it 'emits NOT for an excluded row' do
      expect(q_for(['NOT'], %w[alpha beta]))
        .to eq('((title_quoted:"alpha") NOT (title_quoted:"beta"))')
    end

    it 'emits exactly the booleans it was given, in order' do
      expect(q_for(%w[OR NOT]).scan(/ (AND|OR|NOT) /).flatten).to eq(%w[OR NOT])
      expect(q_for(%w[NOT OR]).scan(/ (AND|OR|NOT) /).flatten).to eq(%w[NOT OR])
      expect(q_for(%w[AND AND]).scan(/ (AND|OR|NOT) /).flatten).to eq(%w[AND AND])
    end

    it 'joins a single row with no boolean at all' do
      expect(q_for([], %w[alpha])).to eq('(title_quoted:"alpha")')
    end
  end

  describe 'per-row operators' do
    def q_for(op, query: 'red planet', field: 'title')
      params = BlacklightMcp::QueryBuilder.advanced(rows: [{ query: query, field: field, op: op }])
      solr_params(params)['q']
    end

    it 'AND requires every word, boosted by a match on the whole phrase' do
      expect(q_for('AND')).to eq('((title:"red" AND title:"planet") OR title_phrase:"red planet")')
    end

    it 'OR accepts any word' do
      expect(q_for('OR')).to eq('(title:"red" OR title:"planet")')
    end

    it 'phrase searches the field\'s quoted index, as one phrase' do
      expect(q_for('phrase')).to eq('(title_quoted:"red planet")')
    end

    it 'begins_with searches the left-anchored field' do
      expect(q_for('begins_with')).to eq('(title_starts:"red planet")')
    end
  end

  describe 'search fields' do
    it 'searches all_fields with no field prefix' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'moby', search_field: 'all_fields')
      expect(solr_params(params)['q']).to eq('("moby") OR phrase:"moby"')
    end

    it 'targets the Solr field configured for the search field' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'moby', search_field: 'title')
      expect(solr_params(params)['q']).to include('title:"moby"')
    end

    it 'carries a search field\'s format restriction into q' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'nature', search_field: 'journaltitle')
      expect(solr_params(params)['q']).to include('format:"Journal/Periodical"')
    end
  end

  describe 'facet filters' do
    it 'OR-s several values of one facet into a single filter query' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', formats: %w[Book Microform])
      solr = solr_params(params)

      expect(solr['fq']).to include('{!lucene}{!query v=$f_inclusive.format.0} OR {!query v=$f_inclusive.format.1}')
      expect(solr['f_inclusive.format.0']).to eq('{!term f=format}Book')
      expect(solr['f_inclusive.format.1']).to eq('{!term f=format}Microform')
    end

    it 'emits a plain term filter for a single OR-ed value' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', formats: ['Book'])
      expect(solr_params(params)['fq']).to include('{!term f=format}Book')
    end

    it 'AND-s conjunctive filters as separate filter queries' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', filters_all: { 'format' => %w[Book Microform] })
      expect(solr_params(params)['fq']).to include('{!term f=format}Book', '{!term f=format}Microform')
    end

    it 'filters languages' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', languages: ['English'])
      expect(solr_params(params)['fq']).to include('{!term f=language_facet}English')
    end

    it 'filters on any configured facet field' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', filters: { 'online' => ['Online'] })
      expect(solr_params(params)['fq']).to include('{!term f=online}Online')
    end

    it 'combines facets from different fields as separate filter queries' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', formats: ['Book'], languages: ['German'])
      expect(solr_params(params)['fq']).to include('{!term f=format}Book', '{!term f=language_facet}German')
    end
  end

  describe 'date range' do
    it 'becomes an inclusive Solr range filter' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', date_range: { begin: 1966, end: 2025 })
      expect(solr_params(params)['fq']).to include('pub_date_facet:[1966 TO 2025]')
    end

    it 'requests the stats Blacklight needs to draw the range facet' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', date_range: { begin: 1966, end: 2025 })
      expect(solr_params(params)['stats.field']).to include('pub_date_facet')
    end

    it 'applies to advanced search too' do
      params = BlacklightMcp::QueryBuilder.advanced(rows: [{ query: 'x' }], date_range: { begin: 1900, end: 1910 })
      expect(solr_params(params)['fq']).to include('pub_date_facet:[1900 TO 1910]')
    end
  end

  describe 'sort' do
    it 'passes every configured sort through to Solr' do
      BlacklightMcp::CatalogOptions.sort_options.each do |option|
        params = BlacklightMcp::QueryBuilder.simple(query: 'x', sort: option['sort'])
        expect(solr_params(params)['sort']).to eq(option['sort'])
      end
    end

    it 'resolves a label to the same Solr sort as its key' do
      by_label = solr_params(BlacklightMcp::QueryBuilder.simple(query: 'x', sort: 'year ascending'))
      expect(by_label['sort']).to eq('pub_date_sort asc, title_sort asc')
    end

    it 'falls back to the catalog default when no sort is given' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x')
      expect(solr_params(params)['sort']).to eq(CatalogController.blacklight_config.default_sort_field.sort)
    end
  end

  describe 'paging' do
    it 'translates page and per_page into Solr start and rows' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', page: 3, per_page: 50)
      solr = solr_params(params)

      expect(solr['rows']).to eq(50)
      expect(solr['start']).to eq(100)
    end

    it 'starts at 0 on the first page' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x', per_page: 5)
      expect(solr_params(params)['start'].to_i).to eq(0)
    end
  end

  describe 'facetting' do
    it 'asks Solr for every facet the catalog displays, so results carry them back' do
      params = BlacklightMcp::QueryBuilder.simple(query: 'x')
      facet_fields = solr_params(params)['facet.field']

      expect(facet_fields).to include('format', 'language_facet', 'online', 'location',
                                      'author_facet', 'pub_date_facet', 'lc_callnum_facet')
    end
  end
end
