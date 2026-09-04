# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::CheckAvailability do
  # The shapes here match what the indexer writes: JSON inside a Solr string,
  # holdings keyed by holdings uuid, and items keyed by the same uuid.
  def document(id: '123', **fields)
    SolrDocument.new({ 'id' => id, 'title_display' => 'Never flinch', 'format' => ['Book'] }.merge(fields))
  end

  let(:holdings) do
    { 'h1' => { 'hrid' => 'ho1', 'call' => 'PS3561 .N48',
                'location' => { 'name' => 'Olin Library Main Collection', 'library' => 'Olin Library' },
                'items' => { 'count' => 2, 'avail' => 1 }, 'active' => true } }.to_json
  end

  let(:items) do
    { 'h1' => [{ 'id' => 'i1', 'status' => { 'status' => 'Available' }, 'copy' => '1',
                 'loanType' => { 'name' => 'Can circulate' } },
               { 'id' => 'i2', 'status' => { 'status' => 'Checked out' }, 'copy' => '2',
                 'enum' => 'v.2' }] }.to_json
  end

  it 'is read-only and takes a list of ids' do
    expect(described_class.name_value).to eq('check_availability')
    expect(described_class.annotations.read_only_hint).to be true
    expect(described_class.input_schema.to_h[:required]).to eq(['ids'])
  end

  describe '.call' do
    it 'reports the holding, its call number and how many items are on the shelf' do
      stub_search_runner(documents: [document(holdings_json: holdings, items_json: items)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record).to include('id' => '123', 'title' => 'Never flinch', 'available_now' => true)
      expect(record['copies'].first).to include(
        'library' => 'Olin Library',
        'location' => 'Olin Library Main Collection',
        'call_number' => 'PS3561 .N48',
        'total_items' => 2,
        'available_items' => 1
      )
      expect(record['summary']).to eq('On the shelf now at Olin Library')
    end

    it 'reports each item with its own status' do
      stub_search_runner(documents: [document(holdings_json: holdings, items_json: items)])
      items = tool_payload(described_class, ids: %w[123])['records'].first['copies'].first['items']

      expect(items).to eq([{ 'status' => 'Available', 'copy' => '1', 'loan_type' => 'Can circulate' },
                           { 'status' => 'Checked out', 'enumeration' => 'v.2', 'copy' => '2' }])
    end

    it 'says so plainly when every copy is out' do
      all_out = { 'h1' => [{ 'id' => 'i1', 'status' => { 'status' => 'Checked out' } }] }.to_json
      stub_search_runner(documents: [document(holdings_json: holdings, items_json: all_out)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record['available_now']).to be false
      expect(record['summary']).to include('none on the shelf right now', 'Checked out')
    end

    it 'treats an online record as available and lists its links' do
      url_access = ['{"url":"https://example.com/book","description":"Connect to full text"}']
      stub_search_runner(documents: [document(url_access_json: url_access)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record).to include('online' => true, 'available_now' => true)
      expect(record['online_access'])
        .to eq([{ 'url' => 'https://example.com/book', 'description' => 'Connect to full text' }])
    end

    it 'falls back to availability_json when the record carries no holdings' do
      availability = { 'available' => true, 'availAt' => { 'Library Annex' => 'PS3561 .N48' } }.to_json
      stub_search_runner(documents: [document(availability_json: availability)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record['copies']).to eq([{ 'library' => 'Library Annex', 'call_number' => 'PS3561 .N48',
                                        'status' => 'Available' }])
      expect(record).to include('available_now' => true)
      expect(record['summary']).to eq('On the shelf now at Library Annex')
    end

    it 'reports an availability_json copy as out when it sits under unavailAt' do
      availability = { 'available' => false, 'unavailAt' => { 'Olin Library' => 'On order as of 12/4/25' } }.to_json
      stub_search_runner(documents: [document(availability_json: availability)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record).to include('available_now' => false)
      expect(record['summary']).to eq('Held at Olin Library, none on the shelf right now (Not on the shelf)')
    end

    # An electronic holding has no location and no items -- only links. Treated
    # as a copy it turns an ebook into "held at the library, status unknown".
    it 'reports an electronic holding as online access, not as a copy on a shelf' do
      electronic = { 'e1' => { 'call' => 'ONLINE', 'online' => true, 'active' => true,
                               'links' => [{ 'url' => 'https://example.com/ebook',
                                             'description' => 'Access this title' }] } }.to_json
      stub_search_runner(documents: [document(holdings_json: electronic)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record['copies']).to eq([])
      expect(record['online_access'])
        .to eq([{ 'url' => 'https://example.com/ebook', 'description' => 'Access this title' }])
      expect(record['summary']).to eq('Online (1 link)')
      expect(record['available_now']).to be true
    end

    it 'does not list the same link twice when both fields carry it' do
      url = 'https://example.com/ebook'
      electronic = { 'e1' => { 'online' => true, 'links' => [{ 'url' => url }] } }.to_json
      stub_search_runner(documents: [document(holdings_json: electronic,
                                              url_access_json: [{ 'url' => url }.to_json])])

      expect(tool_payload(described_class, ids: %w[123])['records'].first['online_access'].size).to eq(1)
    end

    it 'keeps the physical copies of a record that is also online' do
      mixed = { 'e1' => { 'online' => true, 'links' => [{ 'url' => 'https://example.com/ebook' }] },
                'h1' => { 'call' => 'PS3561 .N48', 'active' => true,
                          'location' => { 'name' => 'Olin Main', 'library' => 'Olin Library' },
                          'items' => { 'count' => 1, 'avail' => 1 } } }.to_json
      stub_search_runner(documents: [document(holdings_json: mixed)])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record['copies'].map { |copy| copy['library'] }).to eq(['Olin Library'])
      expect(record['summary']).to eq('Online (1 link). On the shelf now at Olin Library')
    end

    it 'leaves available_now unknown when nothing in the record says either way' do
      stub_search_runner(documents: [document])
      record = tool_payload(described_class, ids: %w[123])['records'].first

      expect(record).not_to have_key('available_now')
      expect(record['summary']).to eq('No holdings are listed for this record in the catalog.')
    end

    it 'names the ids Solr did not return instead of failing the call' do
      stub_search_runner(documents: [document(id: '123')])
      payload = tool_payload(described_class, ids: %w[123 456])

      expect(payload['records'].map { |record| record['id'] }).to eq(['123'])
      expect(payload['not_found']).to eq(['456'])
    end

    it 'survives a holdings field that is not valid JSON' do
      stub_search_runner(documents: [document(holdings_json: 'not json')])
      expect(tool_payload(described_class, ids: %w[123])['records'].first['copies']).to eq([])
    end

    it 'refuses more ids than one Solr fetch should carry' do
      stub_search_runner(documents: [])
      ids = (1..described_class::MAX_IDS + 1).map(&:to_s)

      expect(tool_error(described_class, ids: ids)).to match(/at most #{described_class::MAX_IDS} ids/)
    end

    it 'rejects an empty list' do
      stub_search_runner(documents: [])
      expect(tool_error(described_class, ids: ['  '])).to match(/at least one catalog record id/)
    end
  end
end
