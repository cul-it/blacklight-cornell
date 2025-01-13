require 'rails_helper'

RSpec.describe AeonHelper, type: :helper do
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
          "Vault location" => "K-1-2-3-4-5", 
          "Restrictions" => "sample_restrictions_val" 
        }
      end

      it 'building location is also added to the cslocation so requests can be routed into Awaiting Restriction Review Q' do
        result = helper.xholdings(holdingsHash, itemsHash)
        expected_values = [
          "itemdata[\"sample_barcode_val\"] = {",
          "location: \"K-1-2-3-4-5\",",
          "loc_code: \"rmc library_name\",",
          "cslocation: \"rmc library_name\","
        ]
        expected_values.each do |value|
          expect(result).to include(value)
        end
      end
    end

    context 'when vault location already contains the rmc building code' do
      before do
        itemsHash["hh_foo"].first["rmc"] = {
          "Vault location" => "rmc Rare and Manuscript Collections"
        }
      end
      it 'cslocation does not add the building code' do
        result = helper.xholdings(holdingsHash, itemsHash)
        expected_values = [
          "itemdata[\"sample_barcode_val\"] = {",
          "location: \"rmc Rare and Manuscript Collections\",",
          "loc_code: \"rmc library_name\",",
          "cslocation: \"rmc library_name\","
        ]
        expected_values.each do |value|
          expect(result).to include(value)
        end
      end
    end

    context 'when enum value does not exist but other distinguishing values exist' do
      before do
        itemsHash["hh_foo"].first.delete("enum")
        itemsHash["hh_foo"].first["chron"] = "sample_chron_val"
        itemsHash["hh_foo"].first["caption"] = "sample_caption_val"
      end

      it 'displays the chron value, copy value, and caption' do
        result = helper.xholdings(holdingsHash, itemsHash)
        expect(result).to include("sample_chron_val")
        expect(result).not_to include("sample_enum_val")
        expect(result).to include("sample_copy_val")
        expect(result).to include("sample_caption_val")
      end
    end
  end
end
