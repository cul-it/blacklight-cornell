require 'rails_helper'

describe AdvancedSearchController do
  describe 'GET index' do
    it 'assigns @facets and renders the index template' do
      get :index
      expect(assigns(:facets)['language_facet']).to be_present
      expect(assigns(:facets)['format']).to be_present
      expect(assigns(:facets)['pub_date_facet']).to be_present
      expect(response).to render_template('index')
    end

    context 'invalid request from solr' do
      it 'redirects to advanced_search#index' do
        # Mock solr request and return rsolr error
        rsolr_request_error = RSolr::Error::Http.new(nil, nil)
        allow(rsolr_request_error).to receive(:to_s).and_return('mocked RSolr error')
        allow(subject).to receive(:index).and_raise(rsolr_request_error)

        # Mock environment to test rescue behavior in non-test environments
        allow(Rails.env).to receive(:test?).and_return(false)
        get :index
        expect(response).to redirect_to(advanced_search_index_path)
        expect(request.flash[:notice]).to eq("Sorry, I don't understand your search.")
      end
    end
  end

  describe 'GET edit' do
    it 'assigns @facets and renders the edit template' do
      get :edit, params: { f: { language_facet: ['English'] }, f_inclusive: { language_facet: ['English', 'French'] } }
      expect(assigns(:facets)['language_facet']).to be_present
      expect(assigns(:facets)['format']).to be_present
      expect(assigns(:facets)['pub_date_facet']).to be_present
      expect(response).to render_template('edit')
    end

    context 'invalid request from solr' do
      it 'redirects to advanced_search#index' do
        # Mock solr request and return rsolr error
        rsolr_request_error = RSolr::Error::Http.new(nil, nil)
        allow(rsolr_request_error).to receive(:to_s).and_return('mocked RSolr error')
        allow(subject).to receive(:edit).and_raise(rsolr_request_error)

        # Mock environment to test rescue behavior in non-test environments
        allow(Rails.env).to receive(:test?).and_return(false)
        get :edit
        expect(response).to redirect_to(advanced_search_index_path)
        expect(request.flash[:notice]).to eq("Sorry, I don't understand your search.")
      end
    end
  end
end
