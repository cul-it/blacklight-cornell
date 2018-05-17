require 'spec_helper'

RSpec.feature "user logs in" do
  scenario "using facebook oauth2" do
    stub_omniauth
    visit 'logins' 
    if ENV['FACEBOOK_KEY']
      expect(page).to have_link("Sign in with your facebook id")
      click_link "Sign in with your facebook id"
      expect(page).to have_content("You are logged in as Diligent Tester.")
    else
      expect(page).to_not have_link("Sign in with your facebook id")
    end
  end

  scenario "using facebook oauth2 from search history page" do
    if ENV['FACEBOOK_KEY']
    stub_omniauth
    visit 'search_history' 
    click_link "Sign in"
    expect(page).to have_link("Sign in with your facebook id")
    click_link "Sign in with your facebook id"
    expect(page).to have_content("You are logged in as Diligent Tester.")
    expect(page).to have_content("Search History")
    end
  end

  def stub_omniauth
    # first, set OmniAuth to run in test mode
    OmniAuth.config.test_mode = true
    # then, provide a set of fake oauth data that
    # omniauth will use when a user tries to authenticate:
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
      provider: "facebook",
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
