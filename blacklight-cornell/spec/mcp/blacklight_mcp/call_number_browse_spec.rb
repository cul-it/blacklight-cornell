# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::CallNumberBrowse do
  # A row as the browse collection actually stores it: markup in the citation,
  # the library buried in availability_json, and `online` an array of access
  # values rather than the boolean its name suggests.
  let(:doc) do
    { 'bibid' => 16_155_634,
      'callnum_display' => 'Willis Room GV1469.F67 L43 2010',
      'cite_preescaped_display' => 'Leacock, Matt. <strong>Forbidden island : ' \
                                   'adventure &amp; ... if you dare.</strong> Gamewright, 2010.',
      'fulltitle_display' => 'Forbidden island',
      'format' => ['Object'],
      'availability_json' => '{"available":true,"availAt":{"Uris Library":""}}',
      'online' => ['At the Library'] }
  end

  def entry(overrides = {})
    described_class.send(:entry, doc.merge(overrides))
  end

  it 'keeps the call number whole, location words and all' do
    expect(entry['call_number']).to eq('Willis Room GV1469.F67 L43 2010')
  end

  it 'gives the citation as words rather than markup' do
    expect(entry['citation'])
      .to eq('Leacock, Matt. Forbidden island : adventure & ... if you dare. Gamewright, 2010.')
  end

  # The browse page prints this under each row; it is not in a field of its own.
  it 'finds the library inside availability_json' do
    expect(entry['library']).to eq('Uris Library')
  end

  describe 'availability' do
    it 'says where it is on the shelf' do
      expect(entry['availability']).to eq('On the shelf at Uris Library')
    end

    it 'says where it is not' do
      out = '{"available":false,"unavailAt":{"Olin Library":""}}'

      expect(entry('availability_json' => out)['availability'])
        .to eq('Not on the shelf at Olin Library')
    end

    it 'covers a title that is both online and on a shelf' do
      expect(entry('online' => ['Online'])['availability'])
        .to eq('Online. On the shelf at Uris Library')
    end

    it 'says so plainly when the record reports nothing' do
      expect(entry('availability_json' => nil, 'online' => [])['availability']).to eq('Not reported')
    end

    it 'survives availability_json being unparseable' do
      expect(entry('availability_json' => 'not json')['availability']).to eq('Not reported')
    end
  end

  # A caller lining rows up should never have to tell "no citation on this
  # record" apart from "this key is missing".
  it 'always carries the four columns, even for a record with almost nothing' do
    bare = described_class.send(:entry, { 'bibid' => 1 })

    expect(bare.keys).to include('call_number', 'citation', 'format', 'availability')
    expect(bare['availability']).to eq('Not reported')
  end

  # `online` holds access values, not a boolean -- reading it as one marked every
  # item in the library as not online.
  it 'reads online from the access values' do
    expect(entry['online']).to be false
    expect(entry('online' => ['Online'])['online']).to be true
  end

  it 'carries the catalog id and path, so a row can feed another tool' do
    expect(entry).to include('id' => '16155634', 'path' => '/catalog/16155634')
  end
end
