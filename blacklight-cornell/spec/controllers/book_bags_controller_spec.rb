# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookBagsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:book_bag) { instance_double(BookBag) }
  let(:book_bag_count) { 1 }
  let(:response_obj) { instance_double(Blacklight::Solr::Response, total: 0) }
  let(:documents) { [double('doc')] }
  let(:search_service) { instance_double(Blacklight::SearchService) }
  let(:user) { User.create!(email: 'dev@example.com') }

  before(:all) do
    Mime::Type.register('application/x-endnote-refer', :endnote) unless Mime::Type.lookup_by_extension(:endnote)
    Mime::Type.register('application/endnote+xml', :endnote_xml) unless Mime::Type.lookup_by_extension(:endnote_xml)
    Mime::Type.register('application/x-research-info-systems', :ris) unless Mime::Type.lookup_by_extension(:ris)
  end

  before do
    allow(BookBag).to receive(:new).and_return(book_bag)
    allow(book_bag).to receive(:count).and_return(book_bag_count)
    allow(book_bag).to receive(:cache).and_return(true)
    allow(book_bag).to receive(:uncache).and_return(true)
    allow(book_bag).to receive(:index).and_return([])
    allow(book_bag).to receive(:clear).and_return(true)
    allow(book_bag).to receive(:create_all)
    allow(book_bag).to receive(:set_bagname)
    allow(book_bag).to receive(:debug)
    allow_any_instance_of(BookBagsController).to receive(:search_service).and_return(search_service)
    allow(search_service).to receive(:search_results).and_return([response_obj, documents])
    allow(search_service).to receive(:fetch).and_return([response_obj, documents])
    allow_any_instance_of(BookBagsController).to receive(:save_bookmarks_for_book_bags)
    allow_any_instance_of(BookBagsController).to receive(:additional_response_formats)
    allow_any_instance_of(BookBagsController).to receive(:document_export_formats)
    allow_any_instance_of(BookBagsController).to receive(:current_user).and_return(user)
    controller.instance_variable_set(:@bb, book_bag) if described_class == BookBagsController
  end

  describe Bookmarklite do
    it 'stores the document id' do
      bookmark = Bookmarklite.new('abc123')
      expect(bookmark.document_id).to eq('abc123')
    end
  end

  describe '#action_success_redirect_path' do
    it 'returns the book bags index path' do
      controller.singleton_class.define_method(:book_bags_index) { '/book_bags/index' }
      expect(controller.action_success_redirect_path).to eq('/book_bags/index')
    end
  end

  describe '#set_book_bag_name' do
    it 'sets the bag name from the session email' do
      allow(controller).to receive(:current_user).and_return(user)
      session[:cu_authenticated_email] = 'dev@example.com'
      allow(book_bag).to receive(:count).and_return(3)
      expect(book_bag).to receive(:set_bagname).with('dev@example.com-bookbag-default')

      controller.instance_variable_set(:@bb, book_bag)
      controller.send(:set_book_bag_name)

      expect(session[:bookbag_count]).to eq(3)
    end
  end

  describe '#can_add' do
    it 'returns true when under the max' do
      current_or_guest = instance_double(User, bookmarks: Array.new(1) { double('bookmark') })
      allow(controller).to receive(:current_or_guest_user).and_return(current_or_guest)
      expect(controller.can_add).to be(true)
    end

    it 'returns false when at the max' do
      current_or_guest = instance_double(User, bookmarks: Array.new(BookBagsController::MAX_BOOKBAGS_COUNT) { double('bookmark') })
      allow(controller).to receive(:current_or_guest_user).and_return(current_or_guest)
      expect(controller.can_add).to be(false)
    end
  end

  describe 'GET add' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'returns JSON for xhr requests' do
      get :add, params: { id: '123' }, xhr: true
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('bookmarks' => { 'count' => book_bag_count })
    end

    it 'renders HTML for normal requests' do
      get :add, params: { id: '123' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders RSS for normal requests' do
      expect {
        get :add, params: { id: '123' }, format: :rss
      }.to raise_error(ActionView::MissingTemplate)
    end

    it 'renders Atom for normal requests' do
      expect {
        get :add, params: { id: '123' }, format: :atom
      }.to raise_error(ActionView::MissingTemplate)
    end

    it 'renders JSON for normal requests' do
      get :add, params: { id: '123' }, format: :json
      expect(JSON.parse(response.body)).to eq({})
    end
  end

  describe 'GET addbookmarks' do
    it 'moves saved bookmarks into the book bag and clears the session' do
      stub_const('BookBagsController::MAX_BOOKBAGS_COUNT', 3)
      bookmarks = ['1', '2', '3', '4']
      allow(book_bag).to receive(:count).and_return(0)
      session[:bookmarks_for_book_bags] = bookmarks
      expect(book_bag).to receive(:create_all).with(['1', '2', '3'])
      get :addbookmarks
      expect(session[:bookmarks_for_book_bags]).to be_nil
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe 'DELETE delete' do
    it 'returns JSON for xhr requests' do
      delete :delete, params: { id: '123' }, xhr: true
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('bookmarks' => { 'count' => book_bag_count })
    end

    it 'renders HTML for normal requests' do
      delete :delete, params: { id: '123' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders RSS for normal requests' do
      expect {
        delete :delete, params: { id: '123' }, format: :rss
      }.to raise_error(ActionView::MissingTemplate)
    end

    it 'renders Atom for normal requests' do
      expect {
        delete :delete, params: { id: '123' }, format: :atom
      }.to raise_error(ActionView::MissingTemplate)
    end

    it 'renders JSON for normal requests' do
      delete :delete, params: { id: '123' }, format: :json
      expect(JSON.parse(response.body)).to eq({})
    end
  end

  describe 'GET index' do
    it 'fetches and assigns documents for a BookBag instance' do
      allow(book_bag).to receive(:is_a?).with(BookBag).and_return(true)
      allow(book_bag).to receive(:index).and_return(%w[1 2])
      expect(search_service).to receive(:search_results).and_return([response_obj, documents])
      get :index
      expect(assigns(:response)).to eq(response_obj)
    end

    it 'fetches and assigns documents when bib ids are prefixed' do
      non_book_bag = instance_double('NonBookBag', index: [String.new('bibid-1')])
      allow(non_book_bag).to receive(:is_a?).with(BookBag).and_return(false)
      controller.instance_variable_set(:@bb, non_book_bag)
      expect(search_service).to receive(:search_results).and_return([response_obj, documents])
      get :index
      expect(assigns(:response)).to eq(response_obj)
    end

    it 'renders RSS' do
      allow(book_bag).to receive(:is_a?).with(BookBag).and_return(true)
      allow(book_bag).to receive(:index).and_return([])
      get :index, format: :rss
      expect(response).to have_http_status(:ok)
    end

    it 'renders Atom' do
      allow(book_bag).to receive(:is_a?).with(BookBag).and_return(true)
      allow(book_bag).to receive(:index).and_return([])
      get :index, format: :atom
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET clear' do
    it 'clears current bookmarks when the book bag clears' do
      bookmarks = ['1', '2']
      current_or_guest = instance_double(User, bookmarks: bookmarks)
      allow(controller).to receive(:current_or_guest_user).and_return(current_or_guest)
      allow(book_bag).to receive(:clear).and_return(true)
      get :clear
      expect(bookmarks).to be_empty
      expect(flash[:notice]).to be_present
    end

    it 'sets an error flash when clear fails' do
      allow(book_bag).to receive(:clear).and_return(false)
      get :clear
      expect(flash[:error]).to be_present
    end
  end

  describe '#action_documents' do
    it 'fetches all documents using per_page rows equal to bag size' do
      allow(book_bag).to receive(:index).and_return(%w[1 2 3])
      controller.instance_variable_set(:@bb, book_bag)
      expect(search_service).to receive(:fetch).with(%w[1 2 3], hash_including(per_page: 3, rows: 3)).and_return([response_obj, documents])
      controller.action_documents
    end
  end

  describe 'GET endnote' do
    it 'fetches when an id is provided' do
      expect(search_service).to receive(:fetch).with('123').and_return([response_obj, documents])
      get :endnote, params: { id: '123' }, format: :endnote
    end

    it 'renders endnote for full bag exports' do
      allow(book_bag).to receive(:index).and_return(['1'])
      get :endnote, format: :endnote
      expect(response).to have_http_status(:ok)
    end

    it 'renders endnote_xml for full bag exports' do
      allow(book_bag).to receive(:index).and_return(['1'])
      get :endnote, format: :endnote_xml
      expect(response).to have_http_status(:ok)
    end

    it 'renders ris for full bag exports' do
      allow(book_bag).to receive(:index).and_return(['1'])
      get :endnote, format: :ris
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET export' do
    it 'redirects to index and logs a message' do
      expect(controller).to receive(:puts).with(a_string_including('book_bags_controler.rb export'))
      get :export
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe '#save_bookmarks_for_book_bags' do
    it 'stores guest bookmarks in the session' do
      allow_any_instance_of(BookBagsController).to receive(:save_bookmarks_for_book_bags).and_call_original
      bookmarks = [double('bookmark', document_id: '1'), double('bookmark', document_id: '2')]
      guest = instance_double(User, bookmarks: bookmarks)
      allow(controller).to receive(:guest_user).and_return(guest)
      controller.send(:save_bookmarks_for_book_bags)
      expect(session[:bookmarks_for_book_bags]).to eq(%w[1 2])
    end
  end

  describe '#get_saved_bookmarks' do
    it 'returns saved bookmarks from the session' do
      session[:bookmarks_for_book_bags] = %w[1 2]
      expect(controller.send(:get_saved_bookmarks)).to eq(%w[1 2])
    end
  end

  describe '#clear_saved_bookmarks' do
    it 'clears saved bookmarks from the session' do
      session[:bookmarks_for_book_bags] = %w[1 2]
      controller.send(:clear_saved_bookmarks)
      expect(session[:bookmarks_for_book_bags]).to be_nil
    end
  end

  describe '#developer_bookbag?' do
    it 'returns true when debug user is set in development mode' do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(Rails.env).to receive(:test?).and_return(false)
      expect(controller.send(:developer_bookbag?)).to be(true)
    end
  end

  describe '#authenticate' do
    it 'calls dev sign in when developer mode is enabled' do
      allow(controller).to receive(:developer_bookbag?).and_return(true)
      allow(controller).to receive(:dev_sign_in)
      allow(controller).to receive(:current_user).and_return(nil)
      controller.send(:authenticate)
      expect(controller).to have_received(:dev_sign_in)
    end
  end

  describe '#dev_sign_in' do
    it 'returns early if already signed in' do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      expect(BlacklightCornell::OmniauthMock).not_to receive(:sign_in!)
      expect(controller).not_to receive(:redirect_post)
      controller.send(:dev_sign_in)
    end

    it 'configures omniauth and redirects to saml' do
      allow(controller).to receive(:user_signed_in?).and_return(false)
      allow(controller).to receive(:book_bags_index_path).and_return('/book_bags/index')
      allow(controller).to receive(:user_saml_omniauth_authorize_path).and_return('/users/auth/saml')
      allow(controller).to receive(:redirect_post)
      controller.send(:dev_sign_in)
      expect(controller).to have_received(:redirect_post).with('/users/auth/saml', options: { authenticity_token: :auto })
    end
  end
end
