require 'rails_helper'
RSpec.describe SearchHistoryHelper, type: :helper do
  let(:blacklight_config) { CatalogController.blacklight_config }

  before do
    without_partial_double_verification do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
      allow(helper).to receive(:search_state).and_return(CatalogController.search_state_class.new({}, blacklight_config, helper))
    end
  end

  def normalized_text(html)
    CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(html)).gsub(/\u00A0/, ' ').gsub(/\s+/, ' ').strip
  end

  def parsed_query(href_or_html)
    href = href_or_html[%r{href="([^"]+)"}, 1] || href_or_html
    q    = URI(href).query
    Rack::Utils.parse_nested_query(q || '')
  end


  # History link ---------------------------------------------------------------
  describe '#link_to_custom_search_history_link' do
    it 'renders Search/Filter/Include chips and builds an advanced URL' do
      params = {
        advanced_query: 'yes',
        boolean_row: { '1' => 'AND' },
        f: { language_facet: ['Cebuano'] },
        f_inclusive: { language_facet: %w[English French] },
        op_row: %w[AND AND],
        q_row: ['Canada', ''],
        search_field: 'advanced',
        search_field_row: %w[all_fields all_fields],
        sort: 'score desc, pub_date_sort desc, title_sort asc',
        controller: 'catalog',
        action: 'index',
        only_path: true
      }

      html = helper.link_to_custom_search_history_link(params)
      text = normalized_text(html)

      expect(text).to include('Search: All Fields: All Canada')
      expect(text).to include('Filter: Language: Cebuano')
      expect(text).to match(/Include:\s+Language:\s+English\s+OR\s+French/)
      expect(html).to include('class="label-text"> Language: </span>')
      expect(html).to include('<span class="query-text">English</span>')
      expect(html).to include('<span class="query-text">French</span>')
      expect(html).to include('<span class="inclusive-or"> OR </span>')

      q = parsed_query(html)
      expect(q['advanced_query']).to eq('yes')
      expect(q['q_row']).to eq(["Canada", ""]) # blank dropped by builder
      expect(q['op_row']).to eq(["AND", "AND"])
      expect(q['search_field_row']).to eq(["all_fields", "all_fields"])
      expect(q['f']['language_facet']).to eq(['Cebuano'])
      expect(q['f_inclusive']['language_facet']).to eq(%w[English French])
    end
  end


  # chips / groups HTML --------------------------------------------------------
  describe '#build_search_query_tags' do
    it 'includes "Missing" chip when -pub_date_facet indicates missing year' do
      params = {
        q_row: [''],
        search_field_row: ['all_fields'],
        op_row: ['AND'],
        f: {},
        range: { '-pub_date_facet' => ['[* TO *]'] }
      }

      html = helper.build_search_query_tags(params).join
      text = normalized_text(html)
      expect(text).to include('Filter: Publication Year: Missing')
      expect(text).not_to include('Dated:')
    end

    it 'renders Dated group only when both begin and end present' do
      params = {
        q_row: ['term '],
        search_field_row: ['all_fields'],
        op_row: ['AND'],
        range: { pub_date_facet: { begin: '1900', end: '1950' } }
      }

      html = helper.build_search_query_tags(params).join
      text = normalized_text(html)
      expect(text).to include("Dated: Publication Year: 1900 - 1950")
    end

    it 'does NOT render Dated group when only one bound is present' do
      params = {
        q_row: ['term'],
        search_field_row: ['all_fields'],
        op_row: ['AND'],
        range: { pub_date_facet: { 'begin' => '1900', 'end' => '' } }
      }

      html = helper.build_search_query_tags(params).join
      text = normalized_text(html)
      expect(text).not_to include('Dated:')
    end

    it 'renders a boolean chip between nonblank q_row entries' do
      params = {
        q_row: %w[cats dogs],
        search_field_row: %w[all_fields all_fields],
        op_row: %w[AND AND],
        boolean_row: { :"1" => 'OR' }
      }

      html = helper.build_search_query_tags(params).join
      text = normalized_text(html)
      expect(text).to match(/Search:\s+All\s+Fields:\s+All\s+cats\s+OR\s+All\s+Fields:\s+All\s+dogs/)
    end

    it 'renders multiple exclusive facet chips joined with AND' do
      params = {
        q_row: [''],
        search_field_row: ['all_fields'],
        op_row: ['AND'],
        f: { format: %w[Book Article] }
      }

      html = helper.build_search_query_tags(params).join
      text = normalized_text(html)
      expect(text).to match(/Filter:\s+Format:\s+Book\s+AND\s+Format:\s+Article/)
    end

    it 'renders multiple inclusive facet groups, joined with AND, each group with OR between values' do
      params = {
        f_inclusive: {
          language_facet: %w[English French],
          format:        %w[Book Article]
        }
      }

      html = helper.build_search_query_tags(params).join
      text = normalized_text(html)
      expect(text).to match(/Include:\s+Language:\s+English\s+OR\s+French/)
      expect(text).to match(/Format:\s+Book\s+OR\s+Article/)
      expect(text).to match(/English\s+OR\s+French\s+AND\s+Format:/)
    end
  end


  # URL builder ----------------------------------------------------------------
  describe '#build_search_history_url' do
    it 'builds advanced URL with arrays and boolean_row for subsequent rows' do
      params = {
        advanced_query: 'yes',
        q_row: ['alpha', 'beta', ''],
        op_row: %w[AND OR],
        search_field_row: %w[title all_fields],
        boolean_row: { :"1" => 'AND' },
        f: { format: ['Book'] },
        f_inclusive: { language_facet: %w[English French] },
        range: { pub_date_facet: { begin: '1900', end: '1950' } },
        sort: 'score desc, pub_date_sort desc, title_sort asc'
      }

      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)

      expect(parsed['advanced_query']).to eq('yes')
      expect(parsed['q_row']).to eq(["alpha", "beta", ""])
      expect(parsed['op_row']).to eq(%w[AND OR])
      expect(parsed['search_field_row']).to eq(%w[title all_fields])
      expect(parsed['boolean_row']).to eq({ '1' => 'AND' })
      expect(parsed['f']).to eq({ 'format' => ['Book'] })
      expect(parsed['f_inclusive']).to eq({ 'language_facet' => %w[English French] })
      expect(parsed['range']).to include('pub_date_facet' => { 'begin' => '1900', 'end' => '1950' })
    end

    it 'includes "-pub_date_facet" (missing year) values and ignores blanks' do
      params = {
        q_row: [''],
        op_row: ['AND'],
        search_field_row: ['all_fields'],
        range: { '-pub_date_facet' => ['[* TO *]', ''] }
      }

      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)
      expect(parsed['range']).to eq({"-pub_date_facet"=>["[* TO *]", ""]})
    end

    it 'builds basic URL (non-advanced) with single q and search_field' do
      params = {
        q: 'galaxies',
        search_field: 'all_fields',
        f: { format: ['Article'] }
      }

      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)

      expect(parsed['q']).to eq('galaxies')
      expect(parsed['search_field']).to eq('all_fields')
      expect(parsed['f']).to eq({ 'format' => ['Article'] })
      expect(parsed['advanced_query']).to be_nil
      expect(parsed['q_row']).to be_nil
      expect(parsed['op_row']).to be_nil
      expect(parsed['search_field_row']).to be_nil
    end

    it 'omits sort when sort is missing' do
      href   = helper.build_search_history_url({})
      parsed = parsed_query(href)
      expect(parsed['sort']).to be_nil
    end

    it 'encodes sort value safely' do
      params = { sort: 'title_sort asc, pub_date_sort desc' }
      href   = helper.build_search_history_url(params)
      expect(href).to include('sort=')
      expect(parsed_query(href)['sort']).to eq('title_sort asc, pub_date_sort desc')
    end

    it 'omits :f and :f_inclusive when they are empty after blank-dropping' do
      params = {
        f: { format: [''] },
        f_inclusive: { language_facet: [''] }
      }

      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)
      expect(parsed['f']).to eq({ 'format' => [''] })
      expect(parsed['f_inclusive']).to eq({ 'language_facet' => [''] })
    end

    it 'does not add boolean_row for the first query row' do
      params = {
        advanced_query: 'yes',
        q_row: ['alpha'],
        op_row: ['AND'],
        search_field_row: ['all_fields'],
        boolean_row: { :"0" => 'OR' }
      }

      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)
      expect(parsed['boolean_row']).to eq({ '0' => 'OR' })
    end

    it 'does not include advanced arrays when search_type is :basic' do
      params = {
        q_row: ['alpha'],
        op_row: ['AND'],
        search_field_row: ['all_fields'],
        q: 'alpha',
        search_field: 'all_fields'
      }

      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)
      expect(parsed['advanced_query']).to be_nil
      expect(parsed['q_row']).to eq(['alpha'])
      expect(parsed['op_row']).to eq(['AND'])
      expect(parsed['search_field_row']).to eq(['all_fields'])
      expect(parsed['q']).to eq('alpha')
      expect(parsed['search_field']).to eq('all_fields')
    end

    it 'drops blank values in range[-pub_date_facet]' do
      params = {
        range: { '-pub_date_facet' => ['[* TO *]', '', nil] }
      }
      href   = helper.build_search_history_url(params)
      parsed = parsed_query(href)
      expect(parsed['range']).to eq({ '-pub_date_facet' => ['[* TO *]', '', ''] })
    end
  end

  # op label map ---------------------------------------------------------------
  describe '#op_row_label_for' do
    it 'maps operators to display labels, falling back to key' do
      expect(helper.send(:op_row_label_for, 'AND')).to eq('All')
      expect(helper.send(:op_row_label_for, 'OR')).to  eq('Any')
      expect(helper.send(:op_row_label_for, 'phrase')).to eq('Phrase')
      expect(helper.send(:op_row_label_for, 'begins_with')).to eq('Begins with')
      expect(helper.send(:op_row_label_for, 'unknown_op')).to eq('unknown_op')
    end
  end


  # chip structure -------------------------------------------------------------
  context 'HTML structure details for chips' do
    it 'renders chip with filter-name + label-text + query-text spans' do
      params = {
        q_row: ['alpha'],
        search_field_row: ['all_fields'],
        op_row: ['AND']
      }

      html = helper.build_search_query_tags(params).join
      expect(html).to include('combined-label-query')
      expect(html).to include('filter-name')
      expect(html).to include('label-text')
      expect(html).to include('<span class="query-text">alpha</span>')
    end
  end
end
