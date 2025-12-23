# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookmarksController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:bookmarks_relation) { instance_double('BookmarksRelation') }
  let(:where_relation) { instance_double('BookmarkWhereRelation') }
  let(:bookmark_record) { instance_double('BookmarkRecord', delete: true, destroyed?: true) }
  let(:current_or_guest_user) { instance_double(User, bookmarks: bookmarks_relation, persisted?: true, email: 'guest@example.com') }
  let(:token_user) { instance_double(User, bookmarks: bookmark_list) }
  let(:bookmark_list) do
    [
      instance_double('Bookmark', document_id: '1'),
      instance_double('Bookmark', document_id: '2'),
    ]
  end
  let(:response_obj) { instance_double(Blacklight::Solr::Response, total: 0) }
  let(:documents) { [double('doc')] }
  let(:search_service) { instance_double(Blacklight::SearchService) }

  before do
    controller.blacklight_config.document_model = SolrDocument
    allow(controller).to receive(:search_service).and_return(search_service)
    allow(search_service).to receive(:fetch).and_return([response_obj, documents])
    allow(controller).to receive(:additional_response_formats)
    allow(controller).to receive(:document_export_formats)
    allow(controller).to receive(:token_or_current_or_guest_user).and_return(token_user)
    allow(controller).to receive(:current_or_guest_user).and_return(current_or_guest_user)
    allow(controller).to receive(:current_user).and_return(nil)
    allow(current_or_guest_user).to receive(:save!)
    allow(bookmarks_relation).to receive(:count).and_return(0)
    allow(bookmarks_relation).to receive(:where).and_return(where_relation)
    allow(where_relation).to receive(:exists?).and_return(false)
    allow(bookmarks_relation).to receive(:create).and_return(true)
    allow(bookmarks_relation).to receive(:find_by).and_return(bookmark_record)
    allow(bookmarks_relation).to receive(:clear).and_return(true)
  end

  describe '#action_documents' do
    it 'fetches documents for bookmarked ids' do
      expect(search_service).to receive(:fetch).with(%w[1 2]).and_return([response_obj, documents])
      controller.action_documents
    end
  end

  describe '#action_success_redirect_path' do
    it 'returns the bookmarks path' do
      allow(controller).to receive(:bookmarks_path).and_return('/bookmarks')
      expect(controller.action_success_redirect_path).to eq('/bookmarks')
    end
  end

  describe '#search_action_url' do
    it 'uses the catalog search path' do
      allow(controller).to receive(:search_catalog_url).and_return('/catalog?q=test')
      expect(controller.search_action_url(q: 'test')).to eq('/catalog?q=test')
    end
  end

  describe 'GET index' do
    it 'redirects to book bags when a user is signed in and book bags are enabled' do
      allow(BookBag).to receive(:enabled?).and_return(true)
      allow(controller).to receive(:current_user).and_return(instance_double(User))
      get :index
      expect(response).to have_http_status(303)
      expect(response).to redirect_to('/book_bags/index')
    end

    it 'renders the bookmarks list' do
      allow(BookBag).to receive(:enabled?).and_return(false)
      expect(search_service).to receive(:fetch).with(%w[1 2]).and_return([response_obj, documents])
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'limits bookmark ids to the max' do
      allow(BookBag).to receive(:enabled?).and_return(false)
      stub_const('BookBagsController::MAX_BOOKBAGS_COUNT', 1)
      allow(controller).to receive(:token_or_current_or_guest_user).and_return(
        instance_double(User, bookmarks: [instance_double('Bookmark', document_id: '1'), instance_double('Bookmark', document_id: '2')])
      )
      expect(search_service).to receive(:fetch).with(['1']).and_return([response_obj, documents])
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'renders RSS' do
      allow(BookBag).to receive(:enabled?).and_return(false)
      allow(controller).to receive(:render).and_return('')
      get :index, format: :rss
      expect(response).to have_http_status(:ok)
    end

    it 'renders Atom' do
      allow(BookBag).to receive(:enabled?).and_return(false)
      allow(controller).to receive(:render).and_return('')
      get :index, format: :atom
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT update' do
    it 'delegates to create' do
      expect(controller).to receive(:create)
      put :update, params: { id: '123' }
    end
  end

  describe 'POST create' do
    it 'returns JSON for xhr success' do
      allow(bookmarks_relation).to receive(:count).and_return(3)
      post :create, params: { id: '123' }, xhr: true
      expect(JSON.parse(response.body)).to eq('bookmarks' => { 'count' => 3 })
    end

    it 'returns an error for xhr failure' do
      allow(bookmarks_relation).to receive(:create).and_return(false)
      post :create, params: { id: '123' }, xhr: true
      expect(response).to have_http_status(500)
    end

    it 'sets a notice for non-xhr success with bookmarks params' do
      request.env['HTTP_REFERER'] = '/bookmarks'
      params = { bookmarks: [{ document_id: '1', document_type: 'SolrDocument' }] }
      post :create, params: params
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to('/bookmarks')
    end

    it 'sets an error for non-xhr failure' do
      request.env['HTTP_REFERER'] = '/bookmarks'
      allow(bookmarks_relation).to receive(:create).and_return(false)
      post :create, params: { id: '123' }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to('/bookmarks')
    end

    it 'saves the user when not persisted' do
      allow(current_or_guest_user).to receive(:persisted?).and_return(false)
      post :create, params: { id: '123' }, xhr: true
      expect(current_or_guest_user).to have_received(:save!)
    end

    it 'renders the selected item limit partial on RangeError' do
      allow(bookmarks_relation).to receive(:count).and_raise(RangeError)
      post :create, params: { id: '123' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE destroy' do
    it 'returns JSON for xhr success' do
      allow(bookmarks_relation).to receive(:count).and_return(2)
      delete :destroy, params: { id: '123' }, xhr: true
      expect(JSON.parse(response.body)).to eq('bookmarks' => { 'count' => 2 })
    end

    it 'returns an error for xhr failure' do
      allow(bookmarks_relation).to receive(:find_by).and_return(nil)
      delete :destroy, params: { id: '123' }, xhr: true
      expect(response).to have_http_status(500)
    end

    it 'redirects with a notice for non-xhr success with bookmarks params' do
      request.env['HTTP_REFERER'] = '/bookmarks'
      params = { id: '123', bookmarks: [{ document_id: '1', document_type: 'SolrDocument' }] }
      delete :destroy, params: params
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to('/bookmarks')
    end

    it 'redirects with an error for non-xhr failure' do
      request.env['HTTP_REFERER'] = '/bookmarks'
      allow(bookmarks_relation).to receive(:find_by).and_return(nil)
      delete :destroy, params: { id: '123' }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to('/bookmarks')
    end
  end

  describe 'DELETE clear' do
    it 'sets a notice when cleared' do
      allow(bookmarks_relation).to receive(:clear).and_return(true)
      delete :clear
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets an error when clear fails' do
      allow(bookmarks_relation).to receive(:clear).and_return(false)
      delete :clear
      expect(flash[:error]).to be_present
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe 'GET export' do
    it 'redirects to index' do
      get :export
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe '#start_new_search_session?' do
    it 'returns true for index' do
      allow(controller).to receive(:action_name).and_return('index')
      expect(controller.send(:start_new_search_session?)).to be(true)
    end

    it 'returns false for other actions' do
      allow(controller).to receive(:action_name).and_return('show')
      expect(controller.send(:start_new_search_session?)).to be(false)
    end
  end

  describe '#permit_bookmarks' do
    it 'permits bookmark attributes' do
      params = ActionController::Parameters.new(bookmarks: [{ document_id: '1', document_type: 'SolrDocument' }])
      allow(controller).to receive(:params).and_return(params)
      permitted = controller.send(:permit_bookmarks)
      expect(permitted[:bookmarks].first[:document_id]).to eq('1')
      expect(permitted[:bookmarks].first[:document_type]).to eq('SolrDocument')
    end
  end
end