# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::BrowseCallNumbers do
  def entries(count = 2)
    Array.new(count) do |i|
      { 'call_number' => "PS3561.I483 N#{i}", 'citation' => "Author. Title #{i}. Publisher, 2020.",
        'title' => "Title #{i}", 'format' => 'Book', 'library' => 'Olin Library',
        'availability' => 'On the shelf at Olin Library', 'status' => 'On the shelf',
        'online' => false, 'id' => "10#{i}", 'path' => "/catalog/10#{i}" }
    end
  end

  def stub_browse(result = entries)
    captured = {}
    allow(BlacklightMcp::CallNumberBrowse).to receive(:entries) do |**args|
      captured.replace(args)
      result
    end
    captured
  end

  it 'is read-only and needs a call number' do
    expect(described_class.name_value).to eq('browse_call_numbers')
    expect(described_class.annotations.read_only_hint).to be true
    expect(described_class.input_schema.to_h[:required]).to eq(['call_number'])
  end

  describe '.call' do
    it 'walks forward from the call number by default' do
      captured = stub_browse
      payload = tool_payload(described_class, call_number: 'PS3561.I483')

      expect(captured).to include(call_number: 'PS3561.I483',
                                  direction: BlacklightMcp::CallNumberBrowse::FORWARD,
                                  limit: BlacklightMcp::CallNumberBrowse::DEFAULT_LIMIT)
      expect(payload['direction']).to eq('forward')
    end

    it 'walks backward when asked' do
      captured = stub_browse
      tool_payload(described_class, call_number: 'PS3561', direction: 'backward')

      expect(captured[:direction]).to eq('backward')
    end

    # Each entry carries the catalog id, so an assistant can go straight from a
    # shelf neighbour to its record or its availability.
    it 'returns entries a caller can hand to another tool' do
      stub_browse
      entry = tool_payload(described_class, call_number: 'PS3561')['entries'].first

      expect(entry).to include('call_number' => 'PS3561.I483 N0', 'title' => 'Title 0', 'id' => '100')
      expect(entry['url']).to eq('http://test.host/catalog/100')
    end

    # The location words are part of the string this index is ordered by, so the
    # tool must pass them through untouched. Stripping "Willis Room" is what sent
    # a real lookup into a different part of the shelf entirely.
    it 'passes a call number with location words through exactly as given' do
      captured = stub_browse
      tool_payload(described_class, call_number: 'Willis Room GV1469.F67 L43 2010')

      expect(captured[:call_number]).to eq('Willis Room GV1469.F67 L43 2010')
    end

    it 'tells the caller, where they will read it, to keep those words' do
      property = described_class.input_schema.to_h[:properties][:call_number]

      expect(property[:description]).to include('Willis Room', 'copied exactly')
    end

    # The model rebuilding the table its own way each call is what made two
    # identical lookups come out looking different. Handing it one already laid
    # out is the strongest lever there is for a consistent answer.
    describe 'the ready-made table' do
      let(:table) { tool_payload(described_class, call_number: 'PS3561')['table'] }

      before { stub_browse }

      it 'has the columns the catalog browse page shows' do
        expect(table.lines.first).to eq("| Call number | Citation | Format | Library | Status |\n")
      end

      it 'links the call number to the record' do
        expect(table).to include('[PS3561.I483 N0](http://test.host/catalog/100)')
      end

      it 'carries the citation, format, library and status across' do
        # The short status, not the sentence: the sentence is in `entries` for a
        # caller who wants it, but it does not fit a column.
        expect(table).to include('Author. Title 0. Publisher, 2020.', 'Book',
                                 'Olin Library', 'On the shelf')
      end

      it 'says so in words when the shelf is empty there' do
        stub_browse([])

        expect(tool_payload(described_class, call_number: 'ZZZZ')['table'])
          .to eq('No items at or after this call number.')
      end

      # A pipe inside a citation would otherwise split the row into a column.
      it 'escapes a pipe in the data rather than letting it break the row' do
        stub_browse([{ 'call_number' => 'A1', 'citation' => 'Smith | Jones. A book.',
                       'format' => 'Book', 'status' => 'On the shelf' }])
        row = tool_payload(described_class, call_number: 'A1')['table'].lines.last

        # An escaped pipe is still a pipe character, so count only the ones that
        # actually divide columns.
        expect(row).to include('Smith \\| Jones')
        expect(row.scan(/(?<!\\)\|/).length).to eq(6)
      end

      it 'still returns the rows as data, for chaining into other tools' do
        payload = tool_payload(described_class, call_number: 'PS3561')

        expect(payload['entries'].first['id']).to eq('100')
      end
    end

    it 'reports an empty stretch of shelf as empty rather than as an error' do
      stub_browse([])

      expect(tool_payload(described_class, call_number: 'ZZZZ')['entries']).to eq([])
    end

    it 'rejects a direction that is not one of the two' do
      stub_browse
      expect(tool_error(described_class, call_number: 'PS3561', direction: 'sideways'))
        .to match(/direction must be one of/)
    end

    it 'caps how much shelf one call can ask for' do
      stub_browse
      over = BlacklightMcp::CallNumberBrowse::MAX_LIMIT + 1

      expect(tool_error(described_class, call_number: 'PS3561', limit: over))
        .to match(/limit must be between 1 and #{BlacklightMcp::CallNumberBrowse::MAX_LIMIT}/)
    end

    it 'rejects a non-numeric limit' do
      stub_browse
      expect(tool_error(described_class, call_number: 'PS3561', limit: 'ten'))
        .to match(/limit must be a whole number/)
    end

    it 'rejects a blank call number' do
      allow(BlacklightMcp::CallNumberBrowse).to receive(:entries).and_call_original

      expect(tool_error(described_class, call_number: '   ')).to match(/call_number cannot be blank/)
    end
  end
end
