require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  let(:token) { 'token' }
  let(:valid_token_exp) { (Time.now + 1.hour).iso8601 }
  let(:expired_token_exp) { (Time.now - 1.hour).iso8601 }
  let(:response) { { code: 200, token: 'new_token', token_exp: 'new_token_exp' } }
  let(:folio_response) { double('response', body: '{}', code: 200) }

  before do
    allow(CUL::FOLIO::Edge).to receive(:authenticate).and_return(response)
    allow(RestClient).to receive(:get).and_return(folio_response)
  end

  # test the folio_request method to indirectly test the folio_token method
  describe "#folio_request" do
    context 'when the token is nil' do
      it 'DOES fetch a new token from FOLIO' do
        controller.folio_request('http://example.com')
        expect(session[:folio_token]).to eq('new_token')
        expect(session[:folio_token_exp]).to eq('new_token_exp')
      end  
    end

    context 'when the token is present and is not expired' do
      before do
        session[:folio_token] = token
        session[:folio_token_exp] = valid_token_exp
      end
    
      it 'DOES NOT fetch a new token from FOLIO' do
        controller.folio_request('http://example.com')
        expect(session[:folio_token]).to eq(token)
        expect(session[:folio_token_exp]).to eq(valid_token_exp)
      end
    end

    context 'when the token is present and the token is expired' do
        before do
          session[:folio_token] = token
          session[:folio_token_exp] = expired_token_exp
        end

        it 'DOES fetch a new token from FOLIO' do
          controller.folio_request('http://example.com')
          expect(session[:folio_token]).to eq('new_token')
          expect(session[:folio_token_exp]).to eq('new_token_exp')
        end
    end
    
  end
end
