# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::Fetch do
  let(:document) do
    SolrDocument.new('id' => '123', 'title_display' => 'Batman', 'author_display' => 'Kane, Bob',
                     'format' => ['Book'], 'pub_date_display' => '1966',
                     'pub_info_display' => 'New York : DC, 1966.', 'language_display' => ['English'],
                     'subject_display' => ['Comic books', 'Superheroes'],
                     'notes_display' => 'Includes an index.', 'marc_display' => '<record/>')
  end

  it 'is named fetch, which is the name deep research connectors look for' do
    expect(described_class.name_value).to eq('fetch')
    expect(described_class.annotations.read_only_hint).to be true
    expect(described_class.input_schema.to_h[:required]).to eq(['id'])
  end

  describe '.call' do
    before { stub_search_runner(document: document) }

    # Deep research expects exactly these keys back.
    it 'returns id, title, text, url and metadata' do
      expect(tool_payload(described_class, id: '123').keys)
        .to contain_exactly('id', 'title', 'text', 'url', 'metadata')
    end

    it 'identifies and links the record' do
      payload = tool_payload(described_class, id: '123')

      expect(payload['id']).to eq('123')
      expect(payload['title']).to eq('Batman')
      expect(payload['url']).to eq('http://test.host/catalog/123')
    end

    it 'falls back to the catalog path when no host is known' do
      expect(tool_payload(described_class, { id: '123' }, {})['url']).to eq('/catalog/123')
    end

    describe 'the text body' do
      subject(:text) { tool_payload(described_class, id: '123')['text'] }

      it 'leads with the title' do
        expect(text.lines.first.chomp).to eq('Batman')
      end

      it 'writes the record out as labelled lines' do
        expect(text).to include('Author: Kane, Bob')
        expect(text).to include('Format: Book')
        expect(text).to include('Published: New York : DC, 1966.')
        expect(text).to include('Notes: Includes an index.')
      end

      it 'joins a multi-valued field into one line' do
        expect(text).to include('Subjects: Comic books; Superheroes')
      end

      it 'leaves out fields the record does not have' do
        expect(text).not_to include('Edition:')
        expect(text).not_to match(/^\w+: *$/)
      end

      it 'does not dump raw MARC, which is what get_record is for' do
        expect(text).not_to include('<record/>')
      end

      it 'clamps a field that runs on' do
        long = SolrDocument.new('id' => '1', 'title_display' => 'T',
                                'contents_display' => ['x' * 5_000])
        stub_search_runner(document: long)

        contents = tool_payload(described_class, id: '1')['text'].lines.last
        expect(contents.length).to be <= described_class::MAX_FIELD_LENGTH + 20
        expect(contents).to end_with("…\n").or end_with('…')
      end
    end

    it 'puts the summary fields in metadata, without repeating id and title' do
      metadata = tool_payload(described_class, id: '123')['metadata']

      expect(metadata).to include('author' => 'Kane, Bob', 'format' => 'Book')
      expect(metadata.keys).not_to include('id', 'title', 'url', 'path')
    end

    it 'rejects a blank id' do
      expect(tool_error(described_class, id: '  ')).to match(/id is required/)
    end

    it 'reports a missing record as a tool error' do
      runner = instance_double(BlacklightMcp::SearchRunner)
      allow(runner).to receive(:document).and_raise(BlacklightMcp::NotFound, 'No catalog record found with id "nope"')
      allow(BlacklightMcp::SearchRunner).to receive(:new).and_return(runner)

      expect(tool_error(described_class, id: 'nope')).to match(/No catalog record found/)
    end
  end

  it 'is advertised alongside search, so a deep research connector sees the pair' do
    names = BlacklightMcp::Server.tools.map(&:name_value)
    expect(names).to include('search', 'fetch')
  end
end
