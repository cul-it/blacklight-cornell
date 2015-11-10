require 'openssl'
require 'base64'

module BorrowDirect
  # Implements Relais' encryption protocol
  # https://relais.atlassian.net/wiki/display/ILL/Encryption
  #
  # value = BorrowDirect::Encryption.new(public_key_string).encode_with_ts(api_key_or_other_data)
  class Encryption
    attr_reader :public_key_str

    def initialize(a_public_key)
      @public_key_str = a_public_key
    end

    # Will add on timestamp according to Relais protocol, encrypt,
    # and Base64-encode, all per Relais protocol. 
    def encode_with_ts(value)
      # Not sure if this object is thread-safe, so we re-create
      # each time. 

      public_key = OpenSSL::PKey::RSA.new(self.public_key_str)

      payload = "#{value}|#{self.now_timestamp}"

      return Base64.encode64(public_key.public_encrypt(payload))
    end

    # Timestamp formatted how Relais wants it, in UTC
    def now_timestamp
      Time.now.getutc.strftime("%Y%m%d %H%M%S")
    end
  end
end