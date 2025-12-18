# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FOLIO export integration' do
  let(:folio_source) do
    {
      'id' => '16176849',
      'source' => 'FOLIO',
      'author_json' => ['{"name1":"Petrikor Books","search1":"Petrikor Books","type":"Corporate Name"}'],
      'author_addl_json' => [
        '{"name1":"Pahlevi, Areza Akbar","search1":"Pahlevi, Areza Akbar","type":"Personal Name"}',
        '{"name1":"Saimun, Sam, 1924-1972.","search1":"Saimun, Sam, 1924-1972.","type":"Personal Name"}'
      ],
      'fulltitle_display' => "Sam Saimun: Indonesia's Long-Lost Baritone / Written by Areza Akbar Pahlevi.",
      'title_display' => "Sam Saimun: Indonesia's Long-Lost Baritone / Written by Areza Akbar Pahlevi.",
      'publisher_display' => ['Petrikor Books'],
      'pubplace_display' => ['Yogyakarta'],
      'pub_info_display' => ['Yogyakarta : Petrikor Books, 2023.'],
      'pub_date_display' => ['2023'],
      'format' => ['Book']
    }
  end

  let(:document) { SolrDocument.new(folio_source) }

  describe '#get_marc_record_for_export' do
    it 'returns the native MARC record when present' do
      marc_record = instance_double(MARC::Record)
      marc_document = SolrDocument.new('id' => 'm-1', 'source' => 'MARC', 'marc_display' => '<record/>')
      allow(marc_document).to receive(:to_marc).and_return(marc_record)
      expect(FolioMarcAdapter).not_to receive(:new)
      expect(marc_document.get_marc_record_for_export).to eq(marc_record)
    end

    it 'builds a MARC record from FOLIO data via the adapter' do
      expect(FolioMarcAdapter).to receive(:new).with(document).and_call_original
      marc = document.get_marc_record_for_export
      expect(marc).to be_a(MARC::Record)
      expect(marc['001'].value).to eq('16176849')
      expect(marc['110']['a']).to eq('Petrikor Books')
      expect(marc.fields('700').map { |f| f['a'] }).to contain_exactly('Pahlevi, Areza Akbar', 'Saimun, Sam, 1924-1972')
      expect(marc['245']['a']).to eq('Sam Saimun')
      expect(marc['245']['b']).to eq("Indonesia's Long-Lost Baritone")
      expect(marc['245']['c']).to eq('Written by Areza Akbar Pahlevi.')
      expect(marc['264']['a']).to eq('Yogyakarta')
      expect(marc['264']['b']).to eq('Petrikor Books')
      expect(marc['264']['c']).to eq('2023')
    end
  end

  describe '#exportable_record?' do
    it 'is true for FOLIO and MARC sources' do
      marc_document = SolrDocument.new('id' => 'm-1', 'source' => 'MARC', 'marc_display' => '<record/>')
      folio_document = document

      expect(marc_document.exportable_record?).to be true
      expect(folio_document.exportable_record?).to be true
    end

    it 'is false for other sources' do
      other_document = SolrDocument.new('id' => 'x-1', 'source' => 'WorldCat')

      expect(other_document.exportable_record?).to be false
    end
  end

  it 'exports RIS using synthesized MARC' do
    ris = document.export_as_ris

    expect(ris).to include('TY  - BOOK')
    expect(ris).to include("TI  - Sam Saimun: Indonesia's Long-Lost Baritone")
    expect(ris).to include('PY  - 2023')
    expect(ris).to include('PB  - Petrikor Books')
    expect(ris).to include('CY  - Yogyakarta')
  end

  it 'exports EndNote using synthesized MARC' do
    endnote = document.export_as_endnote

    expect(endnote).to include('%0 Book')
    expect(endnote).to include("%T Sam Saimun Indonesia's Long-Lost Baritone")
    expect(endnote).to include('%I Petrikor Books')
    expect(endnote).to include('%C Yogyakarta')
    expect(endnote).to include('%D 2023')
  end

  it 'exports EndNote XML using synthesized MARC' do
    endnote_xml = document.export_as_endnote_xml

    expect(endnote_xml).to include('<ref-type name="Book">6</ref-type>')
    expect(endnote_xml).to include("<title>Sam Saimun: Indonesia's Long-Lost Baritone</title>")
    expect(endnote_xml).to include('<pub-location>Yogyakarta</pub-location>')
    expect(endnote_xml).to include('<publisher>Petrikor Books</publisher>')
  end

  describe 'FolioMarcAdapter edge cases' do
    it 'drops responsibility when it matches the primary author' do
      doc = SolrDocument.new(
        'id' => 'edge-1',
        'source' => 'FOLIO',
        'author_json' => ['{"name1":"Jane Doe","type":"Personal Name"}'],
        'fulltitle_display' => 'Interesting work / Jane Doe'
      )

      adapter = FolioMarcAdapter.new(doc)
      allow(adapter).to receive(:primary_name).and_return('Jane Doe')

      marc = adapter.to_marc
      title_field = marc['245']

      expect(title_field['a']).to eq('Interesting work')
      expect(title_field['c']).to be_nil
    end

    it 'parses pub_info without a place/publisher delimiter' do
      doc = SolrDocument.new(
        'id' => 'edge-2',
        'source' => 'FOLIO',
        'author_json' => ['{"name1":"Org","type":"Corporate Name"}'],
        'fulltitle_display' => 'Title only',
        'pub_info_display' => ['PublisherOnly'],
        'format' => ['Book']
      )

      marc = FolioMarcAdapter.new(doc).to_marc
      pub_field = marc['264']

      expect(pub_field['a']).to be_nil
      expect(pub_field['b']).to eq('PublisherOnly')
      expect(pub_field['c']).to be_nil
    end

    it 'uses meeting tags for meeting name types' do
      doc = SolrDocument.new(
        'id' => 'edge-3',
        'source' => 'FOLIO',
        'author_json' => ['{"name1":"Fancy Conference","type":"Meeting Name"}'],
        'fulltitle_display' => 'Proceedings'
      )

      marc = FolioMarcAdapter.new(doc).to_marc

      expect(marc['111']['a']).to eq('Fancy Conference')
      expect(marc['111'].indicator1).to eq('2')
    end

    it 'ignores invalid or non-hash author JSON entries' do
      doc = SolrDocument.new(
        'id' => 'edge-4',
        'source' => 'FOLIO',
        'author_json' => ['not-json', '123'],
        'author_display' => ['Fallback Author'],
        'fulltitle_display' => 'Fallback title'
      )

      entries = FolioMarcAdapter.new(doc).send(:author_entries)

      expect(entries.map { |e| e[:name] }).to include('Fallback Author')
      expect(entries.length).to eq(1)
    end
  end
end
