# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bookmarks endpoints', type: :request do
  it 'renders the email login required bookmarks view' do
    get '/bookmarks/show_email_login_required_bookmarks'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Email this')
  end

  it 'renders the email login required item view' do
    get '/bookmarks/show_email_login_required_item/123'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Sign in with your NetID')
  end

  it 'renders the selected item limit view' do
    get '/bookmarks/show_selected_item_limit_bookmarks'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Too many bookmarks')
  end

  it 'initiates the book bag login flow' do
    login_path = Rails.application.routes.url_helpers.user_saml_omniauth_authorize_path
    get '/bookmarks/book_bags_login'
    expect([200, 302]).to include(response.status)
    expect(response.body).to include(login_path) if response.status == 200
  end
end
