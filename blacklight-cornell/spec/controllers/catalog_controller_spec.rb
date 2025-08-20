# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  let(:bl_config) { CatalogController.blacklight_config }
  let(:default_sort) { bl_config.default_sort_field.sort }
  let(:callnum) { 'HB172.5%20.F692%202019' }

  shared_examples 'a bad request' do |http_method, action, params|
    it 'returns a 400' do
      expect {
        send(http_method, action, xhr: true, params: params)
      }.to raise_error ActionController::ParameterMissing
    end
  end

  describe 'GET next_callnumber' do
    context 'when request is valid' do
      it 'returns a 200' do
        get :next_callnumber, xhr: true, params: { callnum: callnum, start: 1 }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when request is invalid' do
      include_examples 'a bad request', :get, :next_callnumber, { callnum: 'HB172.5%20.F692%202019' }
      include_examples 'a bad request', :get, :next_callnumber, { start: 1 }
      include_examples 'a bad request', :get, :next_callnumber, {}

      context 'and the X-Requested-With: XMLHttpRequest header is missing' do
        it 'raises an InvalidCrossOriginRequest error' do
          @request.set_header 'HTTP_ACCEPT', 'text/javascript'
          expect {
            get :next_callnumber, params: { callnum: callnum, start: 1 }
          }.to raise_error ActionController::InvalidCrossOriginRequest
        end
      end

      context 'and the Accept header does not include javascript' do
        it 'raises an InvalidCrossOriginRequest error' do
          @request.set_header 'HTTP_X_REQUESTED_WITH', 'XMLHttpRequest'
          @request.set_header 'HTTP_ACCEPT', 'text/html'
          expect {
            get :next_callnumber, params: { callnum: callnum, start: 1 }
          }.to raise_error ActionController::UnknownFormat
        end
      end

      context 'and both the Accept and X-Requested-With headers are missing' do
        it 'raises an UnknownFormat error' do
          expect {
            get :next_callnumber, params: { callnum: callnum, start: 1 }
          }.to raise_error ActionController::UnknownFormat
        end
      end

      context 'and both headers and params are missing' do
        it 'raises a ParameterMissing error' do
          expect {
            get :next_callnumber
          }.to raise_error ActionController::ParameterMissing
        end
      end
    end
  end

  describe 'GET previous_callnumber' do
    context 'when request is valid' do
      it 'returns a 200' do
        get :previous_callnumber, xhr: true, params: { callnum: callnum, start: 1 }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when request is invalid' do
      include_examples 'a bad request', :get, :previous_callnumber, { callnum: 'HB172.5%20.F692%202019' }
      include_examples 'a bad request', :get, :previous_callnumber, { start: 1 }
      include_examples 'a bad request', :get, :previous_callnumber, {}

      context 'and the X-Requested-With: XMLHttpRequest header is missing' do
        it 'raises an InvalidCrossOriginRequest error' do
          @request.set_header 'HTTP_ACCEPT', 'text/javascript'
          expect {
            get :previous_callnumber, params: { callnum: callnum, start: 1 }
          }.to raise_error ActionController::InvalidCrossOriginRequest
        end
      end

      context 'and the Accept header does not include javascript' do
        it 'raises an InvalidCrossOriginRequest error' do
          @request.set_header 'HTTP_X_REQUESTED_WITH', 'XMLHttpRequest'
          @request.set_header 'HTTP_ACCEPT', 'text/html'
          expect {
            get :previous_callnumber, params: { callnum: callnum, start: 1 }
          }.to raise_error ActionController::UnknownFormat
        end
      end

      context 'and both the Accept and X-Requested-With headers are missing' do
        it 'raises an UnknownFormat error' do
          expect {
            get :previous_callnumber, params: { callnum: callnum, start: 1 }
          }.to raise_error ActionController::UnknownFormat
        end
      end

      context 'and headers and params are missing' do
        it 'raises a ParameterMissing error' do
          expect {
            get :previous_callnumber
          }.to raise_error ActionController::ParameterMissing
        end
      end
    end
  end

  describe 'GET build_carousel' do
    context 'when request is valid' do
      it 'returns a 200' do
        get :build_carousel, xhr: true, params: { callnum: callnum }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when request is invalid' do
      include_examples 'a bad request', :get, :build_carousel, {}

      context 'and the X-Requested-With: XMLHttpRequest header is missing' do
        it 'raises an InvalidCrossOriginRequest error' do
          @request.set_header 'HTTP_ACCEPT', 'text/javascript'
          expect {
            get :build_carousel, params: { callnum: callnum }
          }.to raise_error ActionController::InvalidCrossOriginRequest
        end
      end

      context 'and the Accept header does not include javascript' do
        it 'raises an InvalidCrossOriginRequest error' do
          @request.set_header 'HTTP_X_REQUESTED_WITH', 'XMLHttpRequest'
          @request.set_header 'HTTP_ACCEPT', 'text/html'
          expect {
            get :build_carousel, params: { callnum: callnum }
          }.to raise_error ActionController::UnknownFormat
        end
      end

      context 'and both the Accept and X-Requested-With headers are missing' do
        it 'raises an UnknownFormat error' do
          expect {
            get :build_carousel, params: { callnum: callnum }
          }.to raise_error ActionController::UnknownFormat
        end
      end

      context 'and headers and params are missing' do
        it 'raises a ParameterMissing error' do
          expect {
            get :build_carousel
          }.to raise_error ActionController::ParameterMissing
        end
      end
    end
  end

  describe 'GET index' do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
    end

    describe 'publication year range facet' do
      context 'range provided' do
        it 'returns expected response with documents' do
          get :index, params: { q: '', search_field: 'all_fields', range: { 'pub_date_facet' => { begin: '2000', end: '2020' } } }
          expect(response).to be_successful
          expect(assigns(:response).total).to eq(84)
        end
      end

      context 'range not provided' do
        it 'returns expected response with documents' do
          get :index, params: { q: '', search_field: 'all_fields' }
          expect(response).to be_successful
          expect(assigns(:response).total).to eq(233)
        end
      end

      context 'range provided but missing begin and end vals' do
        it 'returns expected response with documents' do
          get :index, params: { q: '', search_field: 'all_fields', range: { 'pub_date_facet' => { begin: nil, end: nil } } }
          expect(response).to be_successful
          expect(assigns(:response).total).to eq(233)
        end
      end
    end
  end

  describe "Ensure no duplicate saved searches to search history" do
    it "does not create a duplicate for equivalent BASIC search params" do
      params = { "q" => "cat", "search_field" => "all_fields" }

      search_one = controller.send(:find_or_initialize_search_session_from_params, params)
      expect(Search.count).to eq(1)
      expect(session[:history]).to eq([search_one.id])

      search_two = controller.send(:find_or_initialize_search_session_from_params, params)
      expect(Search.count).to eq(1), "should not create a second Search"
      expect(search_two.id).to eq(search_one.id), "should reuse the same SavedSearch"
      expect(session[:history].uniq).to eq([search_one.id]), "history should contain only one id"
    end

    it "Creates multiple search entries with different params for Basic search" do
      params1 = { "q" => "cat", "search_field" => "all_fields" }
      params2 = { "q" => "dog", "search_field" => "all_fields" }

      search_one = controller.send(:find_or_initialize_search_session_from_params, params1)
      expect(Search.count).to eq(1)
      expect(session[:history]).to eq([search_one.id])

      controller.send(:find_or_initialize_search_session_from_params, params2) # search_two
      expect(Search.count).to eq(2), "should create a second Search"
      expect(session[:history].count).to eq(2), "history should contain 2 ids"
    end

    it "does not create a duplicate for equivalent ADVANCED search params" do
      params = {
        "advanced_query"   => "yes",
        "q_row"            => %w[Batman Superman],
        "op_row"           => %w[AND OR],
        "search_field"     => "advanced",
        "search_field_row" => %w[all_fields all_fields],
        "f_inclusive"      => { "language_facet" => %w[English French] },
        "range"            => { "pub_date_facet" => { "begin" => "1900", "end" => "1950" } },
      }

      search_one = controller.send(:find_or_initialize_search_session_from_params, params)
      expect(Search.count).to eq(1)
      expect(session[:history].count).to eq(1)

      search_two = controller.send(:find_or_initialize_search_session_from_params, params)
      expect(Search.count).to eq(1), "should not create a second Search for equivalent advanced query"
      expect(search_two.id).to eq(search_one.id)
      expect(session[:history].count).to eq(1)
    end
  end
end