require 'rails_helper'

RSpec.describe CornellCatalogHelper, type: :helper do
  describe '#aspace_pui_url' do
    let(:document_with_aspace) do
      {
        'marc_display' => <<-XML
          <record>
            <datafield tag="035">
              <subfield code="a">(CULAspace)11111</subfield>
            </datafield>
            <datafield tag="035">
              <subfield code="a">(CULAspaceURI)/repositories/2/resources/2345</subfield>
            </datafield>
            <datafield tag="035">
              <subfield code="a">(OCoLC)0000000001</subfield>
            </datafield>
          </record>
        XML
      }
    end

    let(:document_with_missing_repoid) do
      {
        'marc_display' => <<-XML
          <record>
            <datafield tag="035">
              <subfield code="a">(CULAspaceURI)/repositories//resources/2345</subfield>
            </datafield>
          </record>
        XML
      }
    end

    let(:document_with_missing_itemid) do
      {
        'marc_display' => <<-XML
          <record>
            <datafield tag="035">
              <subfield code="a">(CULAspaceURI)/repositories/2/resources/</subfield>
            </datafield>
          </record>
        XML
      }
    end

    let(:document_with_invalid_aspace_format) do
      {
        'marc_display' => <<-XML
          <record>
            <datafield tag="035">
              <subfield code="a">(CULAspaceURI)24234234234234</subfield>
            </datafield>
          </record>
        XML
      }
    end

    let(:document_without_aspace_value) do
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

    context 'when the environment var AEON_PUI_REQUEST is present' do
        before do
          allow(ENV).to receive(:[]).with('AEON_PUI_REQUEST').and_return('http://example.com')
        end
        
        it 'returns link if the document contains a valide CULAspaceURI value' do
          expect(helper.aspace_pui_url(document_with_aspace)).to eq("http://example.com/repositories/2/resources/2345")
        end
    
        it 'returns nil if the document does not contain a CULAspaceURI value' do
          expect(helper.aspace_pui_url(document_without_aspace_value)).to be nil
        end

        it 'returns nil if the CULAspaceURI value is missing the repoid' do
          expect(helper.aspace_pui_url(document_with_missing_repoid)).to be nil
        end

        it 'returns nil if the CULAspaceURI value is missing the itemid' do
          expect(helper.aspace_pui_url(document_with_missing_itemid)).to be nil
        end

        it 'returns nil if the CULAspaceURI value is invalid format' do
          expect(helper.aspace_pui_url(document_with_invalid_aspace_format)).to be nil
        end
    end

    context 'when the environment var AEON_PUI_REQUEST is NOT present' do
        before do
          allow(ENV).to receive(:[]).with('AEON_PUI_REQUEST').and_return(nil)
        end
        
        it 'returns nil regardless of the marc 035 field value' do
          expect(helper.aspace_pui_url(document_with_aspace)).to be nil
          expect(helper.aspace_pui_url(document_without_aspace_value)).to be nil
        end
    end

    it 'returns nil if the document does not have a marc_display field' do
      expect(helper.aspace_pui_url({})).to be nil
    end
  end
end