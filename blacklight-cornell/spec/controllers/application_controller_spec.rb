require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'ok'
    end
  end

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
      routes.draw { get 'index' => 'anonymous#index' }
      allow(controller).to receive(:current_user).and_return(user)
      session[:cu_authenticated_email] = 'bookbag-initial@example.com'
      allow(BookBag).to receive(:new).and_return(book_bag)
      allow(book_bag).to receive(:set_bagname)
      allow(book_bag).to receive(:count).and_return(3)
    end

    it 'loads book bag count in session on initial request' do
      get :index

      expect(book_bag).to have_received(:set_bagname).with('bookbag-initial@example.com-bookbag-default')
      expect(session[:bookbag_count]).to eq(3)
    end
  end
end
