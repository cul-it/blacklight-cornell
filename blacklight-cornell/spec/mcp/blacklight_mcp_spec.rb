# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp do
  describe '.enabled?' do
    def mcp(value)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MCP', '').and_return(value)
    end

    it 'is on when nothing says otherwise' do
      expect(described_class).to be_enabled
    end

    it 'is off for MCP=false' do
      mcp('false')

      expect(described_class).not_to be_enabled
    end

    it 'ignores the case it is written in' do
      %w[FALSE False fAlSe].each do |value|
        mcp(value)

        expect(described_class).not_to be_enabled, "#{value.inspect} should turn it off"
      end
    end

    # Only the word false. A typo must not take the endpoint down, and neither
    # should someone assuming another spelling works.
    it 'stays on for anything that is not the word false' do
      ['', 'true', '0', 'no', 'off', 'maybe', 'falsey'].each do |value|
        mcp(value)

        expect(described_class).to be_enabled, "#{value.inspect} should leave it on"
      end
    end
  end
end
