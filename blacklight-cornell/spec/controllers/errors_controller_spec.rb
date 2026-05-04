require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  describe 'book bag count initialization' do
    let(:user) { User.create!(email: 'bookbag-initial@example.com') }
    let(:book_bag) { instance_double(BookBag) }

    around do |example|
      original_bag_host = ENV['BAG_MYSQL_HOST']
      ENV['BAG_MYSQL_HOST'] = 'test-host'
      example.run
      ENV['BAG_MYSQL_HOST'] = original_bag_host
    end

    before do
      allow(controller).to receive(:current_user).and_return(user)
      session[:cu_authenticated_email] = 'bookbag-initial@example.com'
      allow(BookBag).to receive(:new).and_return(book_bag)
      allow(book_bag).to receive(:set_bagname)
      allow(book_bag).to receive(:count).and_return(3)
    end

    it 'loads book bag count in session on initial request' do
      get :not_found

      expect(book_bag).to have_received(:set_bagname).with('bookbag-initial@example.com-bookbag-default')
      expect(session[:bookbag_count]).to eq(3)
    end
  end

  describe "GET #not_found" do
    it "returns http success" do
      get :not_found
      expect(response).to have_http_status(:missing)
    end
  end

  describe "GET #internal_server_error" do
    it "returns http success" do
      get :internal_server_error
      expect(response).to have_http_status(:error)
    end
  end

end
