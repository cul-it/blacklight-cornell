require "rails_helper"

RSpec.describe AdvancedHelper, type: :helper do
  describe "#render_edited_advanced_search" do
    let(:edited_advanced_search) { helper.render_edited_advanced_search(params) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      end
    end

    context 'non-default operators and booleans selected' do
      let(:params) { {
        q_row: ['Severus', 'Lily', 'Boyface Killah', 'English Breakfast'],
        op_row: ['AND', 'OR', 'begins_with', 'phrase'],
        boolean_row: { '1' => 'OR', '2' => 'AND', '3' => 'NOT' },
        search_field_row: ['author', 'title', 'subject', 'series'],
        controller: 'advanced_search',
        action: 'edit',
        advanced_query: 'yes'
      } }

      it 'pre-fills previously selected values' do
        # boolean_row
        expect(edited_advanced_search).to include('name="boolean_row[1]" value="OR" checked="checked"')
        expect(edited_advanced_search).to include('name="boolean_row[2]" value="AND" checked="checked"')
        expect(edited_advanced_search).to include('name="boolean_row[3]" value="NOT" checked="checked"')

        # q_row
        expect(edited_advanced_search).to match(/input[^>]+id="q_row"[^>]+value=Severus/)
        expect(edited_advanced_search).to match(/input[^>]+id="q_row1"[^>]+value='Lily'/)
        expect(edited_advanced_search).to match(/input[^>]+id="q_row2"[^>]+value='Boyface Killah'/)
        expect(edited_advanced_search).to match(/input[^>]+id="q_row3"[^>]+value='English Breakfast'/)

        # op_row
        expect(edited_advanced_search).to match(/id="op_row".+option value="AND" selected/)
        expect(edited_advanced_search).to match(/id="op_row1".+option value="OR" selected/)
        expect(edited_advanced_search).to match(/id="op_row2".+option value="begins_with" selected/)
        expect(edited_advanced_search).to match(/id="op_row3".+option value="phrase" selected/)

        # search_field_row
        expect(edited_advanced_search).to match(/id="search_field_row".+option value="author" selected/)
        expect(edited_advanced_search).to match(/id="search_field_row1".+option value="title" selected/)
        expect(edited_advanced_search).to match(/id="search_field_row2".+option value="subject" selected/)
        expect(edited_advanced_search).to match(/id="search_field_row3".+option value="series" selected/)
      end
    end

    context 'boolean_row is missing' do
      let(:params) { {
        q_row: ['curly', 'moe', 'larry'],
        controller: 'advanced_search',
        action: 'edit',
        advanced_query: 'yes'
      } }

      it 'defaults to selecting the "AND" boolean when boolean_row is missing' do
        pending("Implement this test")
        expect(edited_advanced_search).to include('name="boolean_row[1]" value="AND" checked="checked"')
        expect(edited_advanced_search).to include('name="boolean_row[2]" value="AND" checked="checked"')
      end
    end
  end
end
