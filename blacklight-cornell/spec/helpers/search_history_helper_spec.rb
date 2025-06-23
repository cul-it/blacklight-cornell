require 'rails_helper'
RSpec.describe SearchHistoryHelper, type: :helper do
  describe '#render_display_link' do

    describe '#parseHistoryShowString' do
      it 'returns expected html' do
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

        link_html = helper.link_to_custom_search_history_link(params)
        link_sans_html = strip_tags(link_html)
        expect(link_sans_html).to include('All Fields All Canada')
        expect(SearchHistoryHelper::FACET_LABEL_MAPPINGS[:language_facet]).to eq('Language')
        expect(link_html).to include('<span class="label-text">Language</span>')
        expect(link_html).to include('<span class="query-text">Cebuano</span>')
        expect(link_html).to include('<span class="query-text">English</span>')
        expect(link_html).to include('<span class="query-text">French</span>')
      end
    end
  end
end
