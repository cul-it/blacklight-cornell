require "rails_helper"

RSpec.describe AdvancedHelper, type: :helper do
  let(:params_missing_bools) {
    {
      q_row: ["curly", "moe", "larry"],
      controller: "advanced_search",
      action: "edit",
      advanced_query: "yes"
    }
  }

  describe '#render_edited_advanced_search' do
    it 'defaults to selecting the "AND" boolean when boolean_row is missing' do
      edited_advanced_search = helper.render_edited_advanced_search(params_missing_bools)
      expect(edited_advanced_search).to include('name="boolean_row[1]" value="AND" checked="checked"')
      expect(edited_advanced_search).to include('name="boolean_row[2]" value="AND" checked="checked"')
    end
  end
end
