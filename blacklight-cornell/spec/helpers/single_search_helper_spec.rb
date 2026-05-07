require 'rails_helper'

RSpec.describe SingleSearchHelper, type: :helper do
  describe '#bento_all_results_link' do
    let(:query) { 'peanut butter & jelly' }

    before do
      allow(helper).to receive(:params).and_return({ q: query })
    end

    context 'when key is libguides' do
      it 'returns the correct URL' do
        expect(helper.bento_all_results_link('libguides')).to eq('https://guides.library.cornell.edu/libguides/home')
      end
    end

    context 'when key is ebsco_eds' do
      it 'returns the correct URL with query' do
        expect(helper.bento_all_results_link('ebsco_eds')).to eq("https://discovery.ebsco.com/c/u2yil2/results?q=peanut+butter+%26+jelly")
      end

      it 'returns the correct URL without query' do
        allow(helper).to receive(:params).and_return({})
        expect(helper.bento_all_results_link('ebsco_eds')).to eq('https://discovery.ebsco.com/c/u2yil2')
      end
    end

    context 'when key is digitalCollections' do
      it 'returns the correct URL' do
        expect(helper.bento_all_results_link('digitalCollections')).to eq("https://digital.library.cornell.edu/catalog?utf8=%E2%9C%93&q=peanut+butter+%26+jelly&search_field=all_fields")
      end
    end

    context 'when key is institutionalRepositories' do
      it 'returns the correct path' do
        expect(helper.bento_all_results_link('institutionalRepositories')).to eq('/institutional_repositories/index?q=peanut+butter+%26+jelly')
      end
    end

    context 'when key is catalog' do
      it 'returns the correct path' do
        expect(helper.bento_all_results_link('catalog')).to eq('/catalog?q=peanut+butter+%26+jelly&search_field=all_fields')
      end
    end

    context 'when key is a format (ex. Book)' do
      it 'returns the catalog path with a format facet' do
        expect(helper.bento_all_results_link('Book')).to eq('/catalog?f%5Bformat%5D%5B%5D=Book&q=peanut+butter+%26+jelly&search_field=all_fields')
      end
    end
  end
end
