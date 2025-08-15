require 'rails_helper'
RSpec.describe SearchHistoryHelper, type: :helper do
  describe '#render_display_link' do

    describe '#parseHistoryShowString' do
      it 'returns expected html' do
        search_type = :advanced

        params = {
          advanced_query: 'yes',
          boolean_row: { '1' => 'AND' },
          f: { language_facet: ['Cebuano'] },
          f_inclusive: { language_facet: ['English', 'French'] },
          op_row: ['AND', 'AND'],
          q_row: ['Canada', ''],
          search_field: 'advanced',
          search_field_row: ['all_fields', 'all_fields'],
          sort: 'score desc, pub_date_sort desc, title_sort asc',
          controller: 'catalog',
          action: 'index',
          only_path: true
        }

        link_html = helper.link_to_custom_search_history_link(params, search_type)
        # Normalize text
        link_text = CGI.unescapeHTML(strip_tags(link_html)).gsub(/\u00A0/, ' ').gsub(/\s+/, ' ').strip

        expect(link_text).to match(/Search:\s+All\s+Fields:?\s+All\s+Canada/)
        expect(link_text).to match(/Filter:\s+Language:?\s+Cebuano/)
        expect(link_text).to match(/Include:\s+Language:?\s+English\s+OR\s+French/)
        expect(SearchHistoryHelper::FACET_LABEL_MAPPINGS[:language_facet]).to eq('Language')
        expect(link_html).to match(%r{<span class="label-text">\s*Language:?\s*</span>}m)
        expect(link_html).to include('<span class="query-text">Cebuano</span>')
        expect(link_html).to include('<span class="query-text">English</span>')
        expect(link_html).to include('<span class="query-text">French</span>')
        expect(link_html).to match(%r{<span class="combined-label-query[^>]*>.*?<span class="filter-name">.*?<span class="label-text">\s*Language:?\s*</span>.*?</span>.*?<span class="query-text">English</span>.*?<span class="inclusive-or">\s*OR\s*</span>.*?<span class="query-text">French</span>.*?</span>}m)
      end
    end
  end
end
