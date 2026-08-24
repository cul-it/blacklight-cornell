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

  describe '#request_path' do
    let(:group) { 'Test' }
    let(:id) { '123456' }
    let(:aeon_codes) { ['olin', 'rmc'] }
    let(:scan) { false }
    let(:document) { {} }

    before do
      allow(helper).to receive(:blacklight_cornell_request).and_return(double)
    end

    def mock_standard_env
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SAML_IDP_TARGET_URL').and_return(nil)
    end

    def mock_aeon_request_env(url)
      mock_standard_env
      allow(ENV).to receive(:[]).with('AEON_REQUEST').and_return(url)
    end

    def mock_blank_aeon_env
      mock_standard_env
      allow(ENV).to receive(:[]).with('AEON_REQUEST').and_return('')
      allow(ENV).to receive(:[]).with('AEON_SCAN_REQUEST').and_return(nil)
    end

    def mock_saml_env
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SAML_IDP_TARGET_URL').and_return('http://saml.example.com')
    end

    def mock_aeon_scan_request_env(url)
      mock_standard_env
      allow(ENV).to receive(:[]).with('AEON_REQUEST').and_return('http://aeon.example.com?id=~id~')
      allow(ENV).to receive(:[]).with('AEON_SCAN_REQUEST').and_return(url)
    end

    context 'when group is "Circulating"' do
      let(:group) { 'Circulating' }

      it 'returns the magic_path' do
        mock_standard_env
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path).with('123456').and_return('/magic/path')
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to eq('/magic/path')
      end
    end

    context 'when group is not "Circulating"' do
      it 'returns aeon_req' do
        mock_aeon_request_env('http://aeon.example.com?id=~id~&libid=~libid~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path).and_return('/magic/path')
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to include('http://aeon.example.com')
        expect(result).to include('123456')
        expect(result).to include('olin|rmc')
      end
    end

    context 'when scan is true' do
      let(:scan) { true }

      it 'appends .scan to the id' do
        mock_aeon_request_env('http://aeon.example.com?id=~id~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path).with('123456.scan')
        
        helper.request_path(group, id, aeon_codes, document, scan)
      end
    end

    context 'when SAML_IDP_TARGET_URL is present' do
      it 'uses auth_magic_request_path instead of magic_request_path' do
        mock_saml_env
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path).with('123456')
        expect(helper.blacklight_cornell_request).to receive(:auth_magic_request_path).with('123456').and_return('/auth/magic/path')
        
        group = 'Circulating'
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to eq('/auth/magic/path')
      end
    end

    context 'when AEON_REQUEST is blank' do
      it 'creates aeon_req with /aeon/id pattern' do
        mock_blank_aeon_env
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path)
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to include("/aeon/#{id}")
      end
    end

    context 'when group is "AEON_SCAN_REQUEST"' do
      let(:group) { 'AEON_SCAN_REQUEST' }

      it 'uses AEON_SCAN_REQUEST environment variable' do
        mock_aeon_scan_request_env('http://scan.example.com?id=~id~&libid=~libid~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path)
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to include('http://scan.example.com')
      end
    end

    context 'when document has finding aid URL' do
      let(:document) do
        {
          'url_findingaid_display' => ['http://findingaid.example.com/resource|Some Resource']
        }
      end

      it 'replaces ~fa~ placeholder with the finding aid URL' do
        mock_aeon_request_env('http://aeon.example.com?id=~id~&finding=~fa~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path)
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to include('http://findingaid.example.com/resource')
      end
    end

    context 'when document has no finding aid URL' do
      let(:document) { {} }

      it 'removes the &finding=~fa~ placeholder from aeon_req' do
        mock_aeon_request_env('http://aeon.example.com?id=~id~&finding=~fa~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path)
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).not_to include('~fa~')
        expect(result).not_to include('&finding=')
      end
    end

    context 'when finding aid display is empty array' do
      let(:document) do
        {
          'url_findingaid_display' => []
        }
      end

      it 'removes the &finding=~fa~ placeholder' do
        mock_aeon_request_env('http://aeon.example.com?id=~id~&finding=~fa~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path)
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).not_to include('~fa~')
      end
    end

    context 'when aeon_codes has multiple codes' do
      let(:aeon_codes) { ['olin', 'rmc', 'mann'] }

      it 'joins codes with pipe separator' do
        mock_aeon_request_env('http://aeon.example.com?id=~id~&libid=~libid~')
        expect(helper.blacklight_cornell_request).to receive(:magic_request_path)
        
        result = helper.request_path(group, id, aeon_codes, document, scan)
        
        expect(result).to include('libid=olin|rmc|mann')
      end
    end
  end

  describe '#ill_scan_link' do
    it 'returns nil if one of the required values is missing' do
      expect(helper.ill_scan_link(nil, {'title': 'Test' }, 'Test title', 'Test subtitle')).to be nil
      expect(helper.ill_scan_link('http://illiad', {}, 'Test title', 'Test subtitle')).to be nil
    end

    it 'returns a valid link with title and identifier parameters' do
      link = helper.ill_scan_link('http://illiad.url', { :isbn_display => ['1234567890'] }, 'Test title', 'Test subtitle')
      uri = URI.parse(link)
      expect(uri.host).to eq('illiad.url')
      expect(uri.query).to include('Action=10&Form=30')
      expect(uri.query).to include('rft.title=Test+title')
      expect(uri.query).to include('rft.isbn=1234567890')
    end
  end
end