# frozen_string_literal: true

require 'rails_helper'

BARCODE = 'sample_barcode_val'
VAULT_LOCATION = 'K-1-2-3-4-5'
NAME = 'Library Name'
ID = '1234567890'
HRID = '12345'

RSpec.describe AeonHelper, type: :helper do
  def holdings_hash()
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
          'location' => { 'name' => name, 'code' => 'rmc', 'library' => NAME },
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
      items['rmc'] = rmc_section
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
    items = items_hash(barcode: barcode, nocirc: nocirc, rmc: false, vault: false)
    document = { 'items_json' => items }
    document['items_json']['hh_foo'].delete('barcode') unless barcode
    rmc_section = nil
    if rmc
      rmc_section = {
        'ArchivesSpace Top Container': '12345'
      }
      rmc_section['Vault location'] = VAULT_LOCATION if vault
      document['items_json']['status'] = { 'rmc' => rmc_section }
    end
    document
  end

  def test_generate_script(input, expectations)
    items = if input['empty']
              empty_items_hash
            else
              items_hash(barcode: input[:barcode], nocirc: input[:nocirc], rmc: input[:rmc], vault: input[:vault])
            end
    holdings = holdings_hash
    puts "barcode is #{items}"
    result = helper.xholdings(holdings, items)
    puts "expectations is #{expectations}"

    expected_values = [
      "itemdata[\"#{expectations[:id]}\"] = {",
      "location: \"#{expectations[:location]}\",",
      "loc_code: \"#{expectations[:loc_code]}\",",
      "cslocation: \"#{expectations[:cslocation]}\",",
      "code: \"#{expectations[:code]}\","
    ]
    expected_values.each do |value|
      puts "expected value is #{value}"
      expect(result).to include(value)
    end
  end

  context 'Item info taken from items_hash input' do
    context 'item has barcode' do
      let(:initial_input) { { barcode: true } }

      specify 'noncirculating, vault location missing' do
        input = initial_input.merge(nocirc: true, rmc: true, vault: false)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end

      specify 'noncirculating, vault location present' do
        input = initial_input.merge(nocirc: true, rmc: true, vault: true)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end

      specify 'not noncirc, vault location missing' do
        input = initial_input.merge(nocirc: false, rmc: true, vault: false)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end

      specify 'not noncirc, vault location present' do
        input = initial_input.merge(nocirc: false, rmc: true, vault: true)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end
    end

    context 'item has no barcode' do
      let(:initial_input) { { barcode: false } }

      specify 'noncirculating' do
        input = initial_input.merge(nocirc: true, rmc: true, vault: true)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end

      specify 'not noncirc' do
        input = initial_input.merge(nocirc: false, rmc: true, vault: true)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(input, expectations)
      end
    end
  end

  context 'Item info is taken from the @document items_json' do
    def merged_document(overrides = {})
      base_document.merge(overrides)
    end

    let(:initial_input) { { empty: true } }

    context 'item has barcode' do
      let(:base_document) { document(barcode: true, nocirc: true, rmc: true, vault: true) }

      specify 'noncirculating, vault location missing' do
        @document = merged_document(vault: false)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'noncirculating, vault location present' do
        @document = merged_document
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'not noncirc, vault location missing' do
        @document = merged_document(nocirc: false, vault: false)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'not noncirc, vault location present' do
        @document = merged_document(nocirc: false)
        expectations = { id: BARCODE, location: 'rmc', loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end
    end

    context 'item has no barcode' do
      let(:base_document) { document(barcode: false, nocirc: true, rmc: true, vault: true) }

      specify 'noncirculating' do
        @document = base_document
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end

      specify 'not noncirc' do
        @document = merged_document(nocirc: false)
        expectations = { id: "iid-#{ID}", location: VAULT_LOCATION, loc_code: 'rmc', cslocation: "rmc #{NAME}", code: 'rmc' }
        test_generate_script(initial_input, expectations)
      end
    end
  end
end
