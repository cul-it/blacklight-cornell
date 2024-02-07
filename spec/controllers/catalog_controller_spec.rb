# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do

  # /get_next
  describe "GET next_callnumber as xhr request and required params" do
    it 'returns a 200' do
      get :next_callnumber, xhr: true, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the start parameter is missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :next_callnumber, xhr: true, params: { callnum: 'HB172.5%20.F692%202019'}
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the callnum parameter is missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :next_callnumber, xhr: true, params: { start: 1}
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the both the callnum and start parameters are missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :next_callnumber, xhr: true
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the X-Requested-With: XMLHttpRequest header is missing' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_ACCEPT", "text/javascript"
      expect {
        get :next_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::InvalidCrossOriginRequest
    end
  end

  context 'when the Accept: text/javascript header is missing' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_X _REQUESTED_WITH", "XMLHttpRequest"
      expect {
        get :next_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when the Accept header does not include javascript' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_X _REQUESTED_WITH", "XMLHttpRequest"
      @request.set_header "HTTP_ACCEPT", "text/html"
      expect {
        get :next_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when both the Accept and X-Requested-With headers are missing' do
    it 'raises an UnknownFormat error' do
      expect {
        get :next_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when headers and params are missing' do
    it 'raises an ParameterMissing error' do
      expect {
        get :next_callnumber
      }.to raise_error ActionController::ParameterMissing
    end
  end

  # /get_previous
  describe "GET previous_callnumber as xhr request and required params" do
    it 'returns a 200' do
      get :previous_callnumber, xhr: true, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the start parameter is missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :previous_callnumber, xhr: true, params: { callnum: 'HB172.5%20.F692%202019'}
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the callnum parameter is missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :previous_callnumber, xhr: true, params: { start: 1}
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the both the callnum and start parameters are missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :previous_callnumber, xhr: true
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the X-Requested-With: XMLHttpRequest header is missing' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_ACCEPT", "text/javascript"
      expect {
        get :previous_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::InvalidCrossOriginRequest
    end
  end

  context 'when the Accept: text/javascript header is missing' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_X _REQUESTED_WITH", "XMLHttpRequest"
      expect {
        get :previous_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when the Accept header does not include javascript' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_X _REQUESTED_WITH", "XMLHttpRequest"
      @request.set_header "HTTP_ACCEPT", "text/html"
      expect {
        get :previous_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when both the Accept and X-Requested-With headers are missing' do
    it 'raises an UnknownFormat error' do
      expect {
        get :previous_callnumber, params: { callnum: 'HB172.5%20.F692%202019', start: 1 }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when headers and params are missing' do
    it 'raises an ParameterMissing error' do
      expect {
        get :previous_callnumber
      }.to raise_error ActionController::ParameterMissing
    end
  end

  # /build_carousel
  describe "GET carousel as xhr request and required params" do
    it 'returns a 200' do
      get :build_carousel, xhr: true, params: { callnum: 'HB172.5%20.F692%202019' }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the callnum parameter is missing' do
    it 'raises a ParameterMissing error' do
      expect {
        get :build_carousel, xhr: true
      }.to raise_error ActionController::ParameterMissing
    end
  end

  context 'when the X-Requested-With: XMLHttpRequest header is missing' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_ACCEPT", "text/javascript"
      expect {
        get :build_carousel, params: { callnum: 'HB172.5%20.F692%202019' }
      }.to raise_error ActionController::InvalidCrossOriginRequest
    end
  end

  context 'when the Accept: text/javascript header is missing' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_X _REQUESTED_WITH", "XMLHttpRequest"
      expect {
        get :build_carousel, params: { callnum: 'HB172.5%20.F692%202019' }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when the Accept header does not include javascript' do
    it 'raises an InvalidCrossOriginRequest error' do
      @request.set_header "HTTP_X _REQUESTED_WITH", "XMLHttpRequest"
      @request.set_header "HTTP_ACCEPT", "text/html"
      expect {
        get :build_carousel, params: { callnum: 'HB172.5%20.F692%202019' }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when both the Accept and X-Requested-With headers are missing' do
    it 'raises an UnknownFormat error' do
      expect {
        get :build_carousel, params: { callnum: 'HB172.5%20.F692%202019' }
      }.to raise_error ActionController::UnknownFormat
    end
  end

  context 'when headers and params are missing' do
    it 'raises an ParameterMissing error' do
      expect {
        get :build_carousel
      }.to raise_error ActionController::ParameterMissing
    end
  end

end
