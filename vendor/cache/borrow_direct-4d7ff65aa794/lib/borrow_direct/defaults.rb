require 'borrow_direct'

module BorrowDirect
  # Some defaults for BD requests, including some you might def want to set
  # at app boot, perhaps in a Rails initializer. 
  #
  # To use the production BD system instead of test system:
  #      BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE
  #
  # To set your library's BD symbol as a default:
  #      BorrowDirect::Defaults.library_symbol = "YOURSYMBOL"
  #
  # To set a default generic patron barcode to use for FindItem requests
  #      BorrowDirect::Defaults.find_item_patron_barcode = "99999999999"
  class Defaults
    TEST_API_BASE         = "https://bdtest.relais-host.com/"
    PRODUCTION_API_BASE   = "https://borrow-direct.relais-host.com/"

    TEST_HTML_BASE        = "https://bdtest.relaisd2d.com/service-proxy?command=query"
    PRODUCTION_HTML_BASE  = "https://borrow-direct.relaisd2d.com/service-proxy?command=query"
    
    class << self
      attr_accessor :api_base, :partnership_id, :find_item_patron_barcode, :library_symbol
      attr_accessor :html_base_url
      attr_accessor :api_key

      # used for HTTPClient send, connection, AND receive timeouts, so
      # theoretically could take 3x this, but unlikely, usually it's just
      # receive that might timeout. In seconds. Default 30s.
      attr_accessor :timeout    
    end

    self.api_base       = BorrowDirect::Defaults::TEST_API_BASE
    self.partnership_id = "BD"
    self.timeout        = 30
    self.html_base_url  = TEST_HTML_BASE

    self.api_key        = nil

  end
end