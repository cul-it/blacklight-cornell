require 'rails_helper'

RSpec.describe BlacklightCornell::VirtualBrowse, type: :module do
  describe '#get_googlebooks_image' do
    let(:oclc) { 'OCLC:703104497' }
    let(:isbn) { 'ISBN:0387978445' }
    let(:format_string) { 'Book' }

    before do
      stub_request(:get, "https://books.google.com/books?bibkeys=#{oclc}&callback=?&jscmd=viewapi")
        .to_return(body: "var _GBSBookInfo = {\"#{oclc}\": {\"thumbnail_url\": \"http://example.com/image.jpg\"}}", status: 200,
                   headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns image url when response is successful' do
      expect(described_class.get_googlebooks_image(oclc, isbn, format_string)).to eq('http://example.com/image.jpg')
    end

    context 'when response is unsuccessful' do
      before do
        stub_request(:get, "https://books.google.com/books?bibkeys=#{oclc}&callback=?&jscmd=viewapi")
          .to_return(status: 500)
      end

      it 'returns default image' do
        expect(described_class.get_googlebooks_image(oclc, isbn, format_string)).to eq('cornell/virtual-browse/book_cvr.png')
      end
    end

    context 'when no thumbnail_url is present' do
      before do
        stub_request(:get, "https://books.google.com/books?bibkeys=#{oclc}&callback=?&jscmd=viewapi")
          .to_return(body: "var _GBSBookInfo = {\"#{oclc}\": {}}", status: 200,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns default image' do
        expect(described_class.get_googlebooks_image(oclc, isbn, format_string)).to eq('cornell/virtual-browse/book_cvr.png')
      end
    end
  end
end