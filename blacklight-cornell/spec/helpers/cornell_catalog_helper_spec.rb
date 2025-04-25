require 'rails_helper'

RSpec.describe CornellCatalogHelper, type: :helper do
  describe '#aspace_pui_id?' do
    let(:document_with_aspace) do
      {
        'marc_display' => <<-XML
          <record>
            <datafield tag="035">
              <subfield code="a">(CULAspace)11111</subfield>
            </datafield>
            <datafield tag="035">
              <subfield code="a">(CULAspaceURI)111111</subfield>
            </datafield>
            <datafield tag="035">
              <subfield code="a">(OCoLC)0000000001</subfield>
            </datafield>
          </record>
        XML
      }
    end

    let(:document_without_aspace) do
      {
        'marc_display' => <<-XML
          <record>
            <datafield tag="035">
              <subfield code="a">(CStRLIN)222222</subfield>
            </datafield>
            <datafield tag="035">
              <subfield code="a">(OCoLC)0000000002</subfield>
            </datafield>
          </record>
        XML
      }
    end

    it 'returns true if the document contains a CULAspaceURI item ID' do
      expect(helper.aspace_pui_id?(document_with_aspace)).to be true
    end

    it 'returns false if the document does not contain a CULAspaceURI item ID' do
      expect(helper.aspace_pui_id?(document_without_aspace)).to be false
    end

    it 'returns false if the document does not have a marc_display field' do
      expect(helper.aspace_pui_id?({})).to be false
    end
  end
end