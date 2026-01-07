################################################################################
## Mock auth used in testing and to access Book Bag features in development  ###
################################################################################
module BlacklightCornell
  module OmniauthMock

    def self.saml_auth_hash
      OmniAuth::AuthHash.new(
        provider: "saml",
        "saml_resp" => "hello",
        uid: "12345678910",
        extra: { raw_info: {} },
        info: {
          email: ["ditester@example.com"],
          name: ["Diligent Tester"],
          netid: "jgr25",
          groups: ["staff","student"],
          primary: ["staff"],
          first_name: "Diligent",
          last_name: "Tester"
        },
        credentials: {
          token: "abcdefg12345",
          refresh_token: "12345abcdefg",
          expires_at: DateTime.now
        }
      )
    end

    def self.sign_in!
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:saml] = saml_auth_hash
    end

    def self.disable!
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:saml] = nil
    end
  end
end