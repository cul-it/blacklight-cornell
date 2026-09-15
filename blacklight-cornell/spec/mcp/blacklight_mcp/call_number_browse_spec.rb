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

  describe '.entries' do
    let(:connection) { instance_double(RSolr::Client) }

    # The connection is built once per process; each example here wants its
    # own so the stub below is the one that gets used.
    before do
      described_class.instance_variable_set(:@connection, nil)
      allow(RSolr).to receive(:connect).and_return(connection)
    end

    after { described_class.instance_variable_set(:@connection, nil) }

    it 'walks forward from the call number against the browse handler' do
      expect(connection).to receive(:get)
        .with('browse', params: { q: '["PS3561" TO *]', rows: 10, start: 0, wt: :ruby })
        .and_return('response' => { 'docs' => [doc] })

      entries = described_class.entries(call_number: 'PS3561')

      expect(entries.map { |e| e['id'] }).to eq(['16155634'])
    end

    it 'walks backward against the reverse handler, excluding the call number itself' do
      expect(connection).to receive(:get)
        .with('reverse', params: { q: '[* TO "PS3561"}', rows: 5, start: 0, wt: :ruby })
        .and_return('response' => { 'docs' => [] })

      expect(described_class.entries(call_number: 'PS3561', direction: 'backward', limit: 5)).to eq([])
    end

    # A quote or a backslash would end the range term early and search for
    # itself; the catalog's own browse drops them the same way.
    it 'strips the characters that would break the range query' do
      expect(connection).to receive(:get)
        .with('browse', params: hash_including(q: '["PS3561 .N48  x" TO *]'))
        .and_return({})

      described_class.entries(call_number: ' PS3561\\.N48 "x" ')
    end

    it 'refuses a blank call number before asking Solr' do
      expect(connection).not_to receive(:get)

      expect { described_class.entries(call_number: ' " ') }
        .to raise_error(BlacklightMcp::InvalidArgument, /call_number cannot be blank/)
    end

    it 'returns no rows when Solr sends no docs' do
      allow(connection).to receive(:get).and_return({})

      expect(described_class.entries(call_number: 'PS3561')).to eq([])
    end

    # The catalog path already reports a slow Solr this way, so the tools have
    # one message for it rather than one per transport error.
    it 'reports a timeout the way the catalog path does' do
      allow(connection).to receive(:get).and_raise(Faraday::TimeoutError)

      expect { described_class.entries(call_number: 'PS3561') }
        .to raise_error(Blacklight::Exceptions::RepositoryTimeout, /timed out/)
    end

    it 'treats a refused connection the same way' do
      allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed, 'refused')

      expect { described_class.entries(call_number: 'PS3561') }
        .to raise_error(Blacklight::Exceptions::RepositoryTimeout)
    end

    describe 'the connection' do
      before do
        allow(Blacklight).to receive(:connection_config)
          .and_return(url: 'http://user:secret@solr.example:8983/solr/catalog-core')
      end

      # The callnum collection sits beside the catalog core on the same Solr,
      # so its URL is derived from the catalog's rather than configured twice.
      it 'points at the browse collection next to the catalog core' do
        collection = ENV.fetch('BROWSE_INDEX_CALLNUMBER', 'callnum')
        allow(connection).to receive(:get).and_return({})
        described_class.entries(call_number: 'PS3561')

        expect(RSolr).to have_received(:connect)
          .with(hash_including(url: "http://user:secret@solr.example:8983/solr/#{collection}"))
      end

      it 'honours BROWSE_INDEX_CALLNUMBER for the collection name' do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('BROWSE_INDEX_CALLNUMBER', 'callnum').and_return('shelf')
        allow(connection).to receive(:get).and_return({})

        described_class.entries(call_number: 'PS3561')

        expect(RSolr).to have_received(:connect)
          .with(hash_including(url: 'http://user:secret@solr.example:8983/solr/shelf'))
      end

      # Without these an MCP request could hold a Puma thread open for as long
      # as Solr cared to take.
      it 'carries the same timeouts as the catalog path' do
        allow(connection).to receive(:get).and_return({})
        described_class.entries(call_number: 'PS3561')

        expect(RSolr).to have_received(:connect)
          .with(hash_including(timeout: BlacklightMcp::SearchRunner::SOLR_TIMEOUT,
                               open_timeout: BlacklightMcp::SearchRunner::SOLR_OPEN_TIMEOUT))
      end

      it 'is built once and reused' do
        allow(connection).to receive(:get).and_return({})
        described_class.entries(call_number: 'PS3561')
        described_class.entries(call_number: 'PS3562')

        expect(RSolr).to have_received(:connect).once
      end
    end
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
