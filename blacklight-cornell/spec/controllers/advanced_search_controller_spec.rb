require 'rails_helper'

describe AdvancedSearchController do
  describe 'GET index' do
    it 'assigns @facets and renders the index template' do
      get :index
      expect(assigns(:facets)['language_facet']).to be_present
      expect(response).to render_template('index')
    end
  end

  describe 'GET edit' do
    it 'assigns @facets and renders the edit template' do
      get :edit, params: { f: { language_facet: ['English'] }, f_inclusive: { language_facet: ['English', 'French'] } }
      expect(assigns(:facets)['language_facet']).to be_present
      expect(response).to render_template('edit')
    end
  end
end
