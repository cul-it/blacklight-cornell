require 'rails_helper'

describe BentoSearch::LibguidesEngine do
  subject(:libguides_engine) { described_class.new }

  before do
    stub_request(:post, /oauth\/token/)
      .to_return(body: JSON.dump(access_token: "test-token", expires_in: 3600),
                status: 200,
                headers: { "Content-Type" => "application/json" })

    stub_request(:get, /guides/)
      .to_return(body: JSON.dump([{ "name" => "guide title", "description" => "guide description", "friendly_url" => "https://example.org/123" }]),
                status: 200,
                headers: { "Content-Type" => "application/json" })

  end

  describe '#search' do
    context 'when the LibGuides API returns results' do
      it 'returns a BentoSearch::Results object with the expected attributes' do
        results = libguides_engine.search('test')
        expect(results).to be_a(BentoSearch::Results)
        expect(results.count).to eq(1)
        expect(results.first.title).to eq('guide title')
        expect(results.first.abstract).to eq('guide description')
        expect(results.first.link).to eq('https://example.org/123')
        expect(results.total_items).to eq(0)
      end
    end

    context 'when the LibGuides API returns no friendly url or description' do
      before do
        stub_request(:get, /guides/)
          .to_return(body: JSON.dump([{ "name" => "guide title", "type_label" => "guide type", "url" => "https://example.org/456" }]),
                     status: 200,
                     headers: { "Content-Type" => "application/json" })
      end

      it 'uses the type label as the abstract' do
        results = libguides_engine.search('test')
        expect(results.first.abstract).to eq('guide type')
      end

      it 'uses the url as the link' do
        results = libguides_engine.search('test')
        expect(results.first.link).to eq('https://example.org/456')
      end
    end
  end

  describe '#get_guides_response' do
    context 'when the API returns a successful response' do
      it 'returns parsed guides array' do
        arr = libguides_engine.get_guides_response('test', 'test-token')
        expect(arr).to be_an(Array)
        expect(arr.first['name']).to eq('guide title')
      end
    end

    context 'when the API returns HTTP error' do
      before do
        stub_request(:get, /guides/).to_return(status: 500)
      end
      
      it 'returns empty' do
        arr = libguides_engine.get_guides_response('test', 'test-token')
        expect(arr).to eq([])
      end
    end
  end

  describe '#get_auth_token' do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    context 'when a valid token exists' do
      it 'returns access token string and caches it' do
        token = libguides_engine.get_auth_token
        expect(token).to eq('test-token')

        cached = Rails.cache.read("libguides_auth_token")
        expect(cached).to be_present
        expect(cached[:access_token]).to eq('test-token')
      end
    end

    context 'when the API returns HTTP error' do
      before do
        Rails.cache.delete("libguides_auth_token")
        stub_request(:post, /oauth\/token/).to_return(status: 500)
      end

      it 'returns nil' do
        token = libguides_engine.get_auth_token
        expect(token).to be_nil
      end
    end
  end
end
