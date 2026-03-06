require 'rails_helper'

RSpec.describe TouHelper, type: :helper do
  describe '#tou_display_value' do
    it 'returns label for a hash with label' do
      expect(helper.tou_display_value({ 'label' => 'Test Label', 'value' => 'Test Value' })).to eq('Test Label')
    end

    it 'returns value for a hash without label' do
      expect(helper.tou_display_value({ 'value' => 'Test Value' })).to eq('Test Value')
    end

    it 'returns string for a single value' do
      expect(helper.tou_display_value(42)).to eq('42')
      expect(helper.tou_display_value('foo')).to eq('foo')
    end

    it 'joins array of hashes by label if present' do
      arr = [
        { 'label' => 'A' },
        { 'label' => 'B' },
        { 'label' => 'C' }
      ]
      expect(helper.tou_display_value(arr)).to eq('A; B; C')
    end

    it 'joins array of hashes by value if label missing' do
      arr = [
        { 'value' => 'X' },
        { 'value' => 'Y' }
      ]
      expect(helper.tou_display_value(arr)).to eq('X; Y')
    end

    it 'joins array of mixed hashes and values' do
      arr = [
        { 'label' => 'A' },
        'B',
        { 'value' => 'C' },
        123
      ]
      expect(helper.tou_display_value(arr)).to eq('A; B; C; 123')
    end

    it 'returns empty string for empty array' do
      expect(helper.tou_display_value([])).to eq('')
    end
  end
end
