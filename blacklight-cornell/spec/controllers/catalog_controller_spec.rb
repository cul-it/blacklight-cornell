# frozen_string_literal: true

require 'rails_helper'

before do
  allow(controller).to receive(:current_user).and_return(nil)
end

RSpec.describe CatalogController, type: :controller do
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


  describe '#start_new_search_session?' do
    # prevent calls to Solr server
    before do
      allow_any_instance_of(Blacklight::SearchService).to receive(:search_results).and_return([double('response'), []])
    end

    context "when action is 'index'" do
      before { allow(controller).to receive(:action_name).and_return('index') }
      # return True ------------------------------------------------------------
      it "returns true when search_field, q(query), and f(facet) are present" do
        get :index, params: { search_field: 'all_fields', q: 'test', f: {"collection_tesim"=>["Digital Witchcraft Collection"]} }
        expect(controller.start_new_search_session?).to be true
      end
      it "returns true when search_field and f(facet) are present, while q(query) is blank" do
        get :index, params: { search_field: 'all_fields', q: '', f: {"collection_tesim"=>["Digital Witchcraft Collection"]} }
        expect(controller.start_new_search_session?).to be true
      end
      it "returns true when search_field and q(query) are present, while f(facet) is blank" do
        get :index, params: { search_field: 'all_fields', q: 'test', f: {} }
        expect(controller.start_new_search_session?).to be true
      end
      # return False -----------------------------------------------------------
      it "returns false when search_field, q(query), and f(facet) are blank or nil" do
        get :index, params: { search_field: '', q: '', f: {} }
        expect(controller.start_new_search_session?).to be false
      end
      it "returns false when search_field and q(query) are blank, while f(facet) is present" do
        get :index, params: { search_field: '', q: '', f: {"collection_tesim"=>["Digital Witchcraft Collection"]} }
        expect(controller.start_new_search_session?).to be false
      end
      it "returns false when only search_field is present" do
        get :index, params: { search_field: 'all_fields', q: '', f: {} }
        expect(controller.start_new_search_session?).to be false
      end
      it "returns false when search_field and f(facet) are blank, while q(query) is present" do
        get :index, params: { search_field: '', q: 'search query', f: {} }
        expect(controller.start_new_search_session?).to be false
      end
      it "returns false when search_field is blank, while q(query) and f(facet) are present" do
        get :index, params: { search_field: '', q: 'test query', f: {"collection_tesim"=>["Digital Witchcraft Collection"]} }
        expect(controller.start_new_search_session?).to be false
      end
    end

    context "when action is not 'index'" do
      before { allow(controller).to receive(:action_name).and_return('show') }

      it "returns false regardless of search parameters" do
        get :show, params: { id: 1, search_field: 'title', q: 'query', f: {"collection_tesim"=>["Digital Witchcraft Collection"]} }
        expect(controller.start_new_search_session?).to be false
      end
    end
  end

end