require 'vcr'

# Convenience for using VCR's filter_sensitive_data according to our common
# pattern. 
#
# For a sensitive piece of information, set in your shell environment variable eg:
#
# BD_FINDITEM_PATRON="patron_barcode"
#
# Then call in a test:
#     VCRFilter.sensitive_data! :bd_finditem_patron
#
# In the tests, when you need to use the piece of data somewhere, use
#     VCRFilter[:bd_library_symbol]
#
# eg
#     BorrowDirect::FindItem.new(VCRFilter[:bd_finditem_patron]) 
#
# Optional but recommended, use VCR cassette tags...
#     VCRFilter.sensitive_data!, :bd_finditem_patron, :bd_finditem_tests
#     #...
#     describe "BD finditem items", :vcr => {:tag => :bd_finditem_tests}
#
# When recording a new cassette, the value from ENV will be used in interactions
# with remote service, but won't be saved in your on disk cassettes -- it will
# be saved as eg DUMMY_BD_FINDITEM_PATRON instead. 
#
# When running from recorded cassettes, you don't need to have the ENV defined, but
# when (re-)recording a cassette, you of course do. 
module VCRFilter
  @@data = {}
  def self.[](key) ; @@data[key.to_s.downcase] ; end
  def self.[]=(key, value) ; @@data[key.to_s.downcase] = value ; end

  def self.sensitive_data!(key, vcr_tag = nil)      
    env_key     = key.to_s.upcase
    dummy_value = "DUMMY_#{env_key}"

    self[key] = (ENV[env_key] || dummy_value)

    VCR.configure do |c|
      c.filter_sensitive_data( dummy_value, vcr_tag ) { self[key]  }
    end
  end
end
