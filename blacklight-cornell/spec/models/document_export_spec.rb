# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Marc::DocumentExport do
  let(:document) { SolrDocument.new('id' => 'test', 'source' => 'MARC', 'marc_display' => '<record/>') }

  def build_record
    MARC::Record.new
  end

  describe '#setup_pub_date' do
    it "normalizes 'n.d.' dates to 'n.d'" do
      record = build_record
      record.append(MARC::DataField.new('260', ' ', ' ', ['c', 'n.d.']))

      expect(document.send(:setup_pub_date, record)).to eq('n.d')
    end
  end

  describe '#get_all_authors' do
    it 'handles translators, editors, compilers, authors, meetings, and editor fallback' do
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['c', 'edited by Someone']))
      record.append(MARC::DataField.new('111', '2', ' ', ['a', 'Annual Meeting'], ['q', '(Conference)']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Tina Translator'], ['e', 'trltranslator']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Eddie Editor'], ['e', 'edteditor']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Cory Compiler'], ['e', 'comcompiler']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Alice Author'], ['e', 'autauthor']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Fallback Editor']))

      result = document.send(:get_all_authors, record)

      expect(result[:translators]).to include('Tina Translator')
      expect(result[:editors]).to include('Eddie Editor', 'Fallback Editor')
      expect(result[:compilers]).to include('Cory Compiler')
      expect(result[:primary_authors]).to include('Alice Author')
      expect(result[:meeting_authors]).to include('Annual Meeting (Conference)')
    end
  end

  describe '#setup_series' do
    it 'returns the 490$a value when present' do
      record = build_record
      record.append(MARC::DataField.new('490', '0', '0', ['a', 'Series Title']))

      expect(document.send(:setup_series, record)).to eq('Series Title')
    end
  end

  describe '#setup_medium' do
    it 'maps sound disc digital to CD' do
      record = build_record
      record.append(MARC::DataField.new('300', ' ', ' ', ['a', '1 sound disc'], ['b', 'digital']))

      expect(document.send(:setup_medium, record, 'song')).to eq('CD')
    end

    it 'returns empty string when no matching medium is found' do
      record = build_record
      record.append(MARC::DataField.new('300', ' ', ' ', ['a', '1 artifact']))

      expect(document.send(:setup_medium, record, 'song')).to eq('')
    end
  end

  describe '#setup_thesis_info' do
    it 'handles single-part thesis data' do
      record = build_record
      record.append(MARC::DataField.new('502', ' ', ' ', ['a', 'Ph.D.']))

      thesis = document.send(:setup_thesis_info, record)
      expect(thesis[:type]).to eq('Ph.D.')
      expect(thesis[:inst]).to eq('')
      expect(thesis[:date]).to eq('')
    end

    it 'handles thesis data without commas in the institution/date part' do
      record = build_record
      record.append(MARC::DataField.new('502', ' ', ' ', ['a', 'Thesis--MyUniversity']))

      thesis = document.send(:setup_thesis_info, record)
      expect(thesis[:inst]).to eq('MyUniversity')
      expect(thesis[:date]).to eq('')
    end
  end

  describe '#relation_for_code' do
    it 'finds the relator label for a code' do
      expect(document.send(:relation_for_code, 'edt')).to eq('editor')
    end
  end

  describe '#export_as_endnote_xml' do
    it 'includes tertiary-authors when editors are present' do
      record = build_record
      record.append(MARC::ControlField.new('001', 'edit-xml'))
      record.append(MARC::DataField.new('100', '1', ' ', ['a', 'Primary Person']))
      record.append(MARC::DataField.new('245', '1', '0', ['a', 'Edited work']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Ed Editor'], ['e', 'edteditor']))

      doc = SolrDocument.new('id' => 'edit-xml', 'source' => 'MARC', 'marc_display' => '<record/>', 'format' => ['Book'])
      allow(doc).to receive(:get_marc_record_for_export).and_return(record)

      xml = doc.export_as_endnote_xml

      expect(xml).to include('<tertiary-authors>')
      expect(xml).to include('<author>Ed Editor</author>')
    end
  end

  describe '#export_as_ris' do
    it 'includes multiple authors and editors with the right tags' do
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['a', 'Many authors']))
      record.append(MARC::DataField.new('100', '1', ' ', ['a', 'Primary One']))
      record.append(MARC::DataField.new('100', '1', ' ', ['a', 'Secondary Two']))
      record.append(MARC::DataField.new('100', '1', ' ', ['a', 'Secondary Three']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Editor Person'], ['e', 'edteditor']))

      doc = SolrDocument.new('id' => 'ris-1', 'source' => 'MARC', 'marc_display' => '<record/>', 'format' => ['Book'])
      allow(doc).to receive(:get_marc_record_for_export).and_return(record)

      ris = doc.export_as_ris

      expect(ris).to include("AU  - Primary One")
      expect(ris).to include("A1  - Secondary Two")
      expect(ris).to include("A2  - Secondary Three")
      expect(ris).to include("ED  - Editor Person")
    end
  end

  describe 'Blacklight::Document::Zotero#generate_rdf_authors' do
    it 'renders editors in RDF sequences' do
      doc = SolrDocument.new('id' => 'zot-1', 'source' => 'MARC', 'marc_display' => '<record/>', 'format' => ['Book'])
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['a', 'Edited RDF']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Editor One'], ['e', 'editor']))
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Editor Two'], ['e', 'editor']))
      allow(doc).to receive(:get_marc_record_for_export).and_return(record)

      xml = doc.export_as_rdf_zotero

      expect(xml).to include('<bib:editors>')
      expect(xml).to include('<foaf:surname>Editor One</foaf:surname>')
      expect(xml).to include('<foaf:surname>Editor Two</foaf:surname>')
    end
  end
end
