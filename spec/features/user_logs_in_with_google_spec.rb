require 'spec_helper'

RSpec.feature "user logs in" do
  scenario "using google oauth2" do
    stub_omniauth
    visit 'logins' 
    expect(page).to have_link("Sign in with your google id")
    click_link "Sign in with your google id"
    expect(page).to have_link("Sign out")
    #expect(page).to have_link("Book Bag")
    expect(page).to have_content("Successfully authenticated from Google account")
  end

  def stub_omniauth
    # first, set OmniAuth to run in test mode
    OmniAuth.config.test_mode = true
    # then, provide a set of fake oauth data that
    # omniauth will use when a user tries to authenticate:
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "12345678910",
      info: {
        email: "ditester@example.com",
        first_name: "Diligent",
        last_name: "Tester"
      },
      credentials: {
        token: "abcdefg12345",
        refresh_token: "12345abcdefg",
        expires_at: DateTime.now
      }
    })
  end
end
