require 'rails_helper'

describe BrowseController do
  describe 'GET #index' do
    let(:callnum_locations) {
      ['All', 'Online', 'Asia Collections', 'Bailey Hortorium', 'Catherwood Library',
      'Fine Arts Library', 'Lab of Ornithology', 'Law Library', 'Library Annex',
      'Mann Library', 'Mathematics Library', 'Music Library', 'Olin Library',
      'Rare & Manuscript', 'Spacecraft Planetary Imaging', 'Uris Library', 'Veterinary Library']
    }

    context 'authq is Author' do
      it 'renders index and assigns @headingsResponse' do
        get :index, params: { authq: 'English Chamber Orchestra', browse_type: 'Author' }
        expect(response).to render_template(:index)
        expect(assigns(:headingsResponse)[0]['heading']).to eq('English Chamber Orchestra')
      end
      
      context 'reverse order, previous page' do
        it 'renders index and assigns @headingsResponse' do
          get :index, params: { authq: 'English Chamber Orchestra', browse_type: 'Author', order: 'reverse', start: '0' }
          expect(response).to render_template(:index)
          expect(assigns(:headingsResponse)[0]['heading']).to eq('El-Basha, Hassan')
        end
      end

      context 'forward order, next page' do
        it 'renders index and assigns @headingsResponse' do
          get :index, params: { authq: 'English Chamber Orchestra', browse_type: 'Author', order: 'forward', start: '20' }
          expect(response).to render_template(:index)
          expect(assigns(:headingsResponse)[0]['heading']).to eq('Forster, E. M. (Edward Morgan), 1879-1970.')
        end
      end
    end

    context 'authq is Author-Title' do
      it 'renders index and assigns @headingsResponse' do
        get :index, params: { authq: 'Beethoven, Ludwig van, 1770-1827. | Five piano concertos', browse_type: 'Author-Title' }
        expect(response).to render_template(:index)
        expect(assigns(:headingsResponse)[0]['heading']).to eq('Beethoven, Ludwig van, 1770-1827. | Five piano concertos')
      end
    end

    context 'authq is Subject' do
      it 'renders index and assigns @headingsResponse' do
        get :index, params: { authq: 'China > History', browse_type: 'Subject' }
        expect(response).to render_template(:index)
        expect(assigns(:headingsResponse)[0]['heading']).to eq('China > History')
      end
    end

    context 'authq is Call-Number' do
      it 'renders index and assigns @headingsResponse and @browse_locations' do
        get :index, params: { authq: 'QA1 .I31', fq: 'location:"Library Annex"', browse_type: 'Call-Number' }
        expect(response).to render_template(:index)
        expect(assigns(:headingsResponse)['response']['docs'][0]['callnum_display']).to eq('QA1 .I31')
        expect(assigns(:browse_locations)).to eq(callnum_locations)
      end
    end

    context 'authq is virtual' do
      it 'renders index and assigns @headingsResponse and @browse_locations' do
        get :index, params: { authq: 'QA1 .I31', browse_type: 'virtual' }
        expect(response).to render_template(:index)
        headingsResponse = assigns(:headingsResponse)
        center_item_index = headingsResponse.count / 2
        expect(headingsResponse[center_item_index]['callnumber']).to eq('QA1 .I31')
        expect(assigns(:browse_locations)).to eq(callnum_locations)
      end

      it 'handle escape characters' do
        get :index, params: { authq: 'QA1 .I31\\', browse_type: 'virtual' }
        expect(response).to render_template(:index)
        headingsResponse = assigns(:headingsResponse)
        center_item_index = headingsResponse.count / 2
        expect(headingsResponse[center_item_index]['callnumber']).to eq('QA1 .I31')
      end
    end

    context 'invalid request from solr' do
      it 'redirects to browse#index' do
        # Mock solr request and return rsolr error
        # Can alternatively produce an rsolr error by using an invalid solr search field in fq, e.g. library:"Sage Hall Management Library"
        rsolr_request_error = RSolr::Error::Http.new(nil, nil)
        allow(rsolr_request_error).to receive(:to_s).and_return('mocked RSolr error')
        allow(subject).to receive(:browse_solr).and_raise(rsolr_request_error)

        # Mock environment to test rescue behavior in non-test environments
        allow(Rails.env).to receive(:test?).and_return(false)
        get :index, params: { authq: 'Q141', fq: 'location:"Sage Hall Management Library"', browse_type: 'Call-Number' }
        expect(response).to redirect_to(browse_index_path)
        expect(request.flash[:notice]).to eq("Sorry, I don't understand your search.")
      end
    end
  end
end
