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

end