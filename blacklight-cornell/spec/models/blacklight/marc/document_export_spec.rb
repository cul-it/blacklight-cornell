# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Marc::DocumentExport do
  include_context "marc export fixtures"

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

    it 'extracts numeric dates from 264 fields when 260 is missing' do
      record = build_record
      record.append(MARC::DataField.new('264', ' ', '1', ['c', '[2018]']))
      expect(document.send(:setup_pub_date, record)).to eq('2018')
    end
  end

  describe '.register_export_formats' do
    it 'registers MARC export formats' do
      export_doc = instance_double("Document")
      expect(export_doc).to receive(:will_export_as).with(:xml)
      expect(export_doc).to receive(:will_export_as).with(:marc, "application/marc")
      expect(export_doc).to receive(:will_export_as).with(:marcxml, "application/marcxml+xml")
      expect(export_doc).to receive(:will_export_as).with(:openurl_ctx_kev, "application/x-openurl-ctx-kev")
      described_class.register_export_formats(export_doc)
    end
  end

  describe '#setup_pub_info' do
    it 'uses 264 when 260 is missing' do
      record = build_record
      record.append(MARC::DataField.new('264', ' ', '1', ['a', 'Ithaca'], ['b', 'Test Pub']))
      expect(document.send(:setup_pub_info, record)).to eq('Ithaca: Test Pub')
    end

    it 'returns nil when no publication data is present' do
      record = build_record
      expect(document.send(:setup_pub_info, record)).to be_nil
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

  describe '#get_contrib_roles' do
    it 'captures relator codes from subfields e and 4' do
      record = build_record
      record.append(MARC::DataField.new('700', '1', ' ', ['a', 'Smith, Jane'], ['e', 'Editor'], ['4', 'aut']))
      relators = document.send(:get_contrib_roles, record)
      expect(relators['Smith, Jane']).to include('edt', 'aut')
    end
  end

  describe '#setup_editors_flag' do
    it 'returns false when no editor hint is present' do
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['c', 'by Someone']))
      expect(document.send(:setup_editors_flag, record)).to be(false)
    end
  end

  describe '#alternate_script' do
    it 'returns the 880 linked field when present' do
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['6', '880-01'], ['a', 'Title'], ['b', 'Subtitle']))
      record.append(MARC::DataField.new('880', '1', '0', ['6', '245-01/$1'], ['a', 'Translated'], ['b', 'Alt']))
      field = document.send(:alternate_script, record, '245')
      expect(field.tag).to eq('880')
      expect(field['a']).to eq('Translated')
    end
  end

  describe '#setup_title_info' do
    it 'builds the title with subtitle and trailing period' do
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['a', 'Title'], ['b', 'Subtitle']))
      expect(document.send(:setup_title_info, record)).to eq('Title: Subtitle.')
    end
  end

  describe '#clean_end_punctuation' do
    it 'strips trailing punctuation' do
      expect(document.send(:clean_end_punctuation, 'Title.')).to eq('Title')
      expect(document.send(:clean_end_punctuation, 'Title')).to eq('Title')
    end
  end

  describe '#setup_doi' do
    it 'returns the DOI when 024$2 is doi' do
      record = build_record
      record.append(MARC::DataField.new('024', '7', ' ', ['a', '10.1111/test'], ['2', 'doi']))
      expect(document.send(:setup_doi, record)).to eq('10.1111/test')
    end

    it 'returns an empty string when DOI is not present' do
      record = build_record
      record.append(MARC::DataField.new('024', '7', ' ', ['a', '12345']))
      expect(document.send(:setup_doi, record)).to eq('')
    end
  end

  describe '#setup_edition' do
    it 'returns nil for 1st editions' do
      record = build_record
      record.append(MARC::DataField.new('250', ' ', ' ', ['a', '1st ed.']))
      expect(document.send(:setup_edition, record)).to be_nil
    end

    it 'returns the edition for other values' do
      record = build_record
      record.append(MARC::DataField.new('250', ' ', ' ', ['a', 'Third edition']))
      expect(document.send(:setup_edition, record)).to eq('Third edition')
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

    it 'maps videodisc to DVD when 347 is present' do
      record = build_record
      record.append(MARC::DataField.new('347', ' ', ' ', ['b', 'DVD videodisc']))
      expect(document.send(:setup_medium, record, 'video')).to eq('DVD')
    end

    it 'maps sound disc with 33 rpm to LP' do
      record = build_record
      record.append(MARC::DataField.new('300', ' ', ' ', ['a', '1 sound disc'], ['b', '33 1/3 rpm']))
      expect(document.send(:setup_medium, record, 'song')).to eq('LP')
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

    it 'handles separate thesis subfields' do
      record = build_record
      record.append(MARC::DataField.new('502', ' ', ' ', ['b', 'M.S.'], ['c', 'Cornell'], ['d', '2010.']))
      thesis = document.send(:setup_thesis_info, record)
      expect(thesis[:type]).to eq('M.S.')
      expect(thesis[:inst]).to eq('Cornell')
      expect(thesis[:date]).to eq('2010')
    end

    it 'parses institution and date when comma is present' do
      record = build_record
      record.append(MARC::DataField.new('502', ' ', ' ', ['a', 'Thesis--Cornell Univ.,June 1954']))
      thesis = document.send(:setup_thesis_info, record)
      expect(thesis[:inst]).to eq('Cornell Univ')
      expect(thesis[:date]).to eq('June 1954')
    end
  end

  describe '#relation_for_code' do
    it 'finds the relator label for a code' do
      expect(document.send(:relation_for_code, 'edt')).to eq('editor')
    end
  end

  describe '#code_for_relation' do
    it 'finds the relator code for a label' do
      expect(document.send(:code_for_relation, 'Editor')).to eq('edt')
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
      allow(doc).to receive(:to_marc).and_return(record)
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
      allow(doc).to receive(:to_marc).and_return(record)
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
      allow(doc).to receive(:to_marc).and_return(record)
      xml = doc.export_as_rdf_zotero
      expect(xml).to include('<bib:editors>')
      expect(xml).to include('<foaf:surname>Editor One</foaf:surname>')
      expect(xml).to include('<foaf:surname>Editor Two</foaf:surname>')
    end
  end

  describe 'export_as_openurl_ctx_kev' do
    it 'creates the appropriate context object for books' do
      record = @typical_record.export_as_openurl_ctx_kev('Book')
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=book&amp;rft.btitle=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.au=&amp;rft.date=c2003.&amp;rft.place=Oxon%2C+U.K.+%3B&amp;rft.pub=CABI+Pub.%2C&amp;rft.edition=&amp;rft.isbn=")
      expect(record).not_to match(/.*rft.genre=article.*rft.issn=.*/)
    end

    it 'creates the appropriate context object for journals' do
      record = @typical_record.export_as_openurl_ctx_kev('Journal')
      record_journal_other = @typical_record.export_as_openurl_ctx_kev('Journal/Magazine')
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=article&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.atitle=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.date=c2003.&amp;rft.issn=")
      expect(record_journal_other).to eq(record)
      expect(record).not_to match(/.*rft.genre=book.*rft.isbn=.*/)
    end

    it 'creates the appropriate context object for other content' do
      record = @typical_record.export_as_openurl_ctx_kev('NotARealFormat')
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.creator=&amp;rft.date=c2003.&amp;rft.place=Oxon%2C+U.K.+%3B&amp;rft.pub=CABI+Pub.%2C&amp;rft.format=notarealformat")
      expect(record).not_to match(/.*rft.isbn=.*/)
      expect(record).not_to match(/.*rft.issn=.*/)
    end

    it 'handles array formats and corporate authors' do
      record = build_record
      record.append(MARC::DataField.new('245', '1', '0', ['a', 'Corp title']))
      record.append(MARC::DataField.new('110', '2', ' ', ['a', 'Corp Org'], ['b', 'Division']))
      record.append(MARC::DataField.new('260', ' ', ' ', ['a', 'Ithaca'], ['b', 'Corp Pub'], ['c', '2020']))
      doc = SolrDocument.new('id' => 'corp-1', 'source' => 'MARC', 'marc_display' => '<record/>')
      allow(doc).to receive(:to_marc).and_return(record)
      export = doc.export_as_openurl_ctx_kev(['Book'])
      expect(export).to include('rft.aucorp=')
      expect(export).to include('rft.pub=')
    end
  end

  describe 'export_as_marc binary' do
    it 'exports MARC binary' do
      expect(@typical_record.export_as_marc).to eq(@typical_record.to_marc.to_marc)
    end
  end

  describe 'export_as_marcxml' do
    it 'exports MARCXML' do
      expect(marc_from_xml(@typical_record.export_as_marcxml)).to eq(marc_from_xml(@typical_record.to_marc.to_xml.to_s))
    end
  end

  describe 'export_as_xml' do
    it 'exports MARCXML as xml' do
      expect(marc_from_xml(@typical_record.export_as_xml)).to eq(marc_from_xml(@typical_record.export_as_marcxml))
    end
  end
end
