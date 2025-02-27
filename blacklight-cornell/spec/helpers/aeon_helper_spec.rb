# frozen_string_literal: true

require 'rails_helper'

SKIP_VALUE = 'SKIP'
BARCODE = 'sample_barcode_val'
VAULT_LOCATION = 'K-1-2-3-4-5'
NAME = 'Library Name'
ID = '1234567890'
HRID = '12345'
CODE = 'rmc_location_code'

RSpec.describe AeonHelper, type: :helper do
  def holdings_hash
    {
      'hh_foo' => { 'call': 'Item foo' }
    }
  end

  def items_hash(barcode:, nocirc:, rmc:, vault:)
    name = nocirc ? 'Non-Circulating' : 'Request in advance'
    items = {
      'hh_foo' => [
        {
          'id' => barcode ? BARCODE : ID,
          'location' => { 'name' => name, 'code' => CODE, 'library' => NAME },
          'barcode' => BARCODE,
          'hrid' => HRID,
          'call' => 'sample_call_val',
          'copy' => 'sample_copy_val',
          'enum' => 'sample_enum_val',
          'caption' => 'sample_caption_val'
        }
      ]
    }
    items['hh_foo'].first.delete('barcode') unless barcode
    rmc_section = nil
    if rmc
      rmc_section = {
        'ArchivesSpace Top Container': '12345'
      }
      rmc_section['Vault location'] = VAULT_LOCATION if vault
      items['hh_foo'].first['rmc'] = rmc_section
    end
    items
  end

  def empty_items_hash
    {
      'hh_foo' => []
    }
  end

  def document(barcode:, nocirc:, rmc:, vault:)
    # The items_json section of the document is almost identical to the items_hash input,
    # with the exception that the 'rmc' section, if present, is found within 'status'.
    # holdings_json is similar, except that it's not an array.
    puts "making document with barcode #{barcode}, nocirc #{nocirc}, rmc #{rmc}, vault #{vault}"
    items = items_hash(barcode: barcode, nocirc: nocirc, rmc: false, vault: false)
    document = {
      'items_json' => items,
      'holdings_json' => {
        'hh_foo' => items['hh_foo'][0]
      }
    }
    unless barcode
      document['items_json']['hh_foo'].delete('barcode')
      document['holdings_json']['hh_foo'].delete('barcode')
    end
    rmc_section = nil
    if rmc
      rmc_section = {
        'ArchivesSpace Top Container' => '12345'
      }
      rmc_section['Vault location'] = VAULT_LOCATION if vault
      document['items_json']['hh_foo'][0]['rmc'] = rmc_section
      document['holdings_json']['rmc'] = rmc_section
    end
    document
  end

  def test_generate_script(input, expectations)
    items = if input[:empty]
              empty_items_hash
            elsif input[:noinput]
              {}
            else
              items_hash(barcode: input[:barcode], nocirc: input[:nocirc], rmc: input[:rmc], vault: input[:vault])
            end
    holdings = holdings_hash
    result = helper.xholdings(holdings, items)
    puts "result is #{result}"

    expected_values = {
      id: expectations[:id],
      location: expectations[:location],
      loc_code: expectations[:loc_code],
      cslocation: expectations[:cslocation],
      code: expectations[:code]
    }
    patterns = {
      id: /itemdata\["(.*?)"\]/,
      location: /location: "(.*?)"/,
      loc_code: /loc_code: "(.*?)"/,
      cslocation: /cslocation: "(.*?)"/,
      code: /[^A-Za-z_]code: "(.*?)"/
    }
    actual_values = {}
    patterns.each do |key, pattern|
      match = result.match(pattern)
      actual_values[key] = match[1] if match
    end

    expected_values.each do |key, expected_value|
      actual_value = actual_values[key]
      if expected_value == SKIP_VALUE
        puts "Skipping test for #{key}"
      else
        expect(actual_value).to eq(expected_value), "Expected #{key} to be '#{expected_value}', but got '#{actual_value}'"
      end
    end
  end

  context 'Item info taken from items_hash input' do
    context 'item has barcode' do
      let(:initial_input) { { barcode: true } }

      skip 'This condition seems impossible, since vault location is given a default value' do
        specify 'noncirculating, vault location missing' do
          input = initial_input.merge(nocirc: true, rmc: true, vault: false)
          expectations = { id: BARCODE, location: CODE, loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: 'rmc' }
          test_generate_script(input, expectations)
        end
      end

      specify 'noncirculating, vault location present' do
        input = initial_input.merge(nocirc: true, rmc: true, vault: true)
        expectations = { id: BARCODE, location: VAULT_LOCATION, loc_code: "#{CODE} #{NAME}", cslocation: "#{CODE} #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end

      specify 'not noncirc, vault location missing' do
        input = initial_input.merge(nocirc: false, rmc: true, vault: false)
        expectations = { id: BARCODE, location: "#{CODE} #{NAME}", loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: SKIP_VALUE }
        test_generate_script(input, expectations)
      end

      specify 'not noncirc, vault location present' do
        input = initial_input.merge(nocirc: false, rmc: true, vault: true)
        expectations = { id: BARCODE, location: "#{CODE} #{NAME}", loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: CODE }
        test_generate_script(input, expectations)
      end
    end

    context 'item has no barcode' do
      let(:initial_input) { { barcode: false } }

      specify 'noncirculating' do
        input = initial_input.merge(nocirc: true, rmc: true, vault: true)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: CODE, cslocation: "#{CODE} #{VAULT_LOCATION}", code: CODE }
        test_generate_script(input, expectations)
      end

      specify 'not noncirc' do
        input = initial_input.merge(nocirc: false, rmc: true, vault: true)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: CODE, cslocation: VAULT_LOCATION, code: CODE }
        test_generate_script(input, expectations)
      end
    end
  end

  context 'items_hash is present but empty; item info is taken from the @document items_json' do
    def merged_document(overrides = {})
      base_document.merge(overrides)
    end

    let(:initial_input) { { empty: true } }

    context 'item has barcode' do
      specify 'noncirculating, vault location missing' do
        @document = document(barcode: true, nocirc: true, rmc: true, vault: false)
        expectations = { id: BARCODE, location: CODE, loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'noncirculating, vault location present' do
        @document = document(barcode: true, nocirc: true, rmc: true, vault: true)
        expectations = { id: BARCODE, location: VAULT_LOCATION, loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'not noncirc, vault location missing' do
        @document = document(barcode: true, nocirc: false, rmc: true, vault: false)
        expectations = { id: BARCODE, location: CODE, loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'not noncirc, vault location present' do
        @document = document(barcode: true, nocirc: false, rmc: true, vault: true)
        expectations = { id: BARCODE, location: VAULT_LOCATION, loc_code: CODE, cslocation: SKIP_VALUE, code: CODE }
        test_generate_script(initial_input, expectations)
      end
    end

    context 'item has no barcode' do
      specify 'noncirculating' do
        @document = document(barcode: false, nocirc: true, rmc: true, vault: true)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: CODE }
        test_generate_script(initial_input, expectations)
      end

      specify 'not noncirc' do
        @document = document(barcode: false, nocirc: false, rmc: true, vault: true)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: CODE, cslocation: "#{CODE} #{NAME}", code: CODE }
        test_generate_script(initial_input, expectations)
      end
    end
  end

  describe '#finding_aids_display' do
    let(:single_output) {
      <<~HTML
        <p>
          <i class="fa fa-check" aria-hidden="true"></i>
          <a href='http://example.com'>Example Label</a>
        </p>
      HTML
    }

    it 'returns an empty string if there is no input' do
      expect(helper.finding_aids_display(nil)).to eq('')
    end

    it 'returns the correct HTML for a single finding aid' do
      finding_aids = ['http://example.com|Example Label']
      expect(helper.finding_aids_display(finding_aids)).to eq(single_output.strip.html_safe)
    end

    it 'returns the correct HTML for multiple finding aids' do
      finding_aids = ['http://example.com|Example Label', 'http://example2.com|Example Label 2']
      result = helper.finding_aids_display(finding_aids)
      expect(result).to include('Example Label')
      expect(result).to include('http://example.com')
      expect(result).to include('Example Label 2')
      expect(result).to include('http://example2.com')
    end

    it 'cleans the URL if it ends with /track' do
      finding_aids = ['http://example.com/track|Example Label']
      expect(helper.finding_aids_display(finding_aids)).to eq(single_output.strip.html_safe)
    end

    it 'handles finding aids with no label' do
      finding_aids = ['http://example.com|']
      expected_html = <<~HTML
        <p>
          <i class="fa fa-check" aria-hidden="true"></i>
          <a href='http://example.com'></a>
        </p>
      HTML
      expect(helper.finding_aids_display(finding_aids)).to eq(expected_html.strip.html_safe)
    end

    it 'handles finding aids with no URL' do
      finding_aids = ['|Example Label']
      expected_html = <<~HTML
        <p>
          <i class="fa fa-check" aria-hidden="true"></i>
          <a href=''>Example Label</a>
        </p>
      HTML
      expect(helper.finding_aids_display(finding_aids)).to eq(expected_html.strip.html_safe)
    end
  end
end
