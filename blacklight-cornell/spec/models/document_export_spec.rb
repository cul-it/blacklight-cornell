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
end
