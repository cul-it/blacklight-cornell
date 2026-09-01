# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::GetRecord do
  let(:document) do
    SolrDocument.new('id' => '123', 'title_display' => 'Batman', 'author_display' => 'Kane, Bob',
                     'format' => ['Book'], 'pub_date_display' => '1966',
                     'marc_display' => '<record/>', 'language_display' => ['English'])
  end

  it 'is read-only and requires an id' do
    expect(described_class.name_value).to eq('get_record')
    expect(described_class.annotations.read_only_hint).to be true
    expect(described_class.input_schema.to_h[:required]).to eq(['id'])
  end

  describe '.call' do
    it 'returns the record summary plus every stored field' do
      stub_search_runner(document: document)
      payload = tool_payload(described_class, id: '123')

      expect(payload).to include('id' => '123', 'title' => 'Batman', 'url' => 'http://test.host/catalog/123')
      expect(payload['record']).to include('marc_display' => '<record/>', 'title_display' => 'Batman')
    end

    it 'restricts the full record to the requested fields' do
      stub_search_runner(document: document)
      payload = tool_payload(described_class, id: '123', fields: %w[id title_display])

      expect(payload['record']).to eq('id' => '123', 'title_display' => 'Batman')
    end

    it 'rejects a blank id' do
      stub_search_runner(document: document)
      expect(tool_error(described_class, id: '  ')).to match(/id is required/)
    end

    it 'reports a missing record as a tool error rather than raising' do
      runner = instance_double(BlacklightMcp::SearchRunner)
      allow(runner).to receive(:document).and_raise(BlacklightMcp::NotFound, 'No catalog record found with id "nope"')
      allow(BlacklightMcp::SearchRunner).to receive(:new).and_return(runner)

      expect(tool_error(described_class, id: 'nope')).to match(/No catalog record found/)
    end
  end
end
