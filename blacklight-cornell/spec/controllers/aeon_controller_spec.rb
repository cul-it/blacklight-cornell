require 'rails_helper'

RSpec.describe AeonController, type: :controller do
  describe '#xholdings' do
    let(:holdingsHash) {
      {
        "hh_foo" => { "call": "Item foo" }
      }
    }

    let(:itemsHash) {
      {
        "hh_foo" => [
          {
            "location" => { "name" => "Non-Circulating", "code" => "rmc", "library" => "library_name" },
            "barcode" => "sample_barcode_val",
            "call" => "sample_call_val",
            "copy" => "sample_copy_val",
            "enum" => "sample_enum_val",
            "caption" => "sample_caption_val",
          }
        ]
      }
    }

    context 'when vault location and restrictions are present in the rmc key of itemsHash' do
      before do
        itemsHash["hh_foo"].first["rmc"] = { 
          "Vault location" => "sample_vault_location_val", 
          "Restrictions" => "sample_restrictions_val" 
        }
      end

      it 'building location is also added to the cslocation so requests can be routed into Awaiting Restriction Review Q' do
        result = subject.xholdings(holdingsHash, itemsHash)
        expected_values = [
          "itemdata[\"sample_barcode_val\"] = {",
          "location:\"sample_vault_location_val\",",
          "loc_code:\"sample_vault_location_val\",",
          "cslocation:\"sample_vault_location_val rmc\","
        ]
        expected_values.each do |value|
          expect(result).to include(value)
        end
      end
    end

    context 'when the rmc key in itemsHash does not contain a Restrictions key' do
      before do
        itemsHash["hh_foo"].first["rmc"] = {
          "Vault location" => "rmc Rare and Manuscript Collections"
        }
      end     
      it 'cslocation does not add the building code' do
        result = subject.xholdings(holdingsHash, itemsHash)
        expected_values = [
          "itemdata[\"sample_barcode_val\"] = {",
          "location:\"rmc Rare and Manuscript Collections\",",
          "loc_code:\"rmc Rare and Manuscript Collections\",",
          "cslocation:\"rmc Rare and Manuscript Collections rmc\","
        ]
        expected_values.each do |value|
          expect(result).to include(value)
        end
      end
    end
  end
end