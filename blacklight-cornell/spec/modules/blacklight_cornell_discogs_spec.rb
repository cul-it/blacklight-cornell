require 'rails_helper'

RSpec.describe BlacklightCornell::Discogs, type: :module do
  subject { Class.new.include(described_class) }

  describe "get_discogs_image" do
    before do 
      stub_request(:get, /releases\/12345/)
      .to_return(body: JSON.dump(id: 12345, title: "Fun Music!", images: [{ resource_url: "https://api-img.discogs.com/" }]),
                status: 200,
                headers: { "Content-Type" => "application/json" })
    end
    let(:id) { "12345" }
    it "returns discogs image url" do
      expect(subject.new.get_discogs_image(id)).to eq("https://api-img.discogs.com/")
    end  
  end 

  describe "get_discogs_search_result" do
    before do
      stub_request(:get, /database\/search/)
      .to_return(body: JSON.dump(results: [{ id: 12345, title: "Fun Music!" }]),
                status: 200,
                headers: { "Content-Type" => "application/json" })
    end

    context "solr document includes title and author/responsibility" do 
      let(:doc) { SolrDocument.new({ "title_display": "Fun Music!", "title_responsibility_display": "Cool Artist" }) }
      it "returns discogs search result" do
        expect(subject.new.get_discogs_search_result(doc)).to eq("12345")
      end
    end

    context "solr document does not include required metadata" do
      let(:doc) { SolrDocument.new({ "title_display": "Fun Music!" }) }
      it "does not return discogs search result" do
        expect(subject.new.get_discogs_search_result(doc)).to be_nil
      end
    end
  end 
end
