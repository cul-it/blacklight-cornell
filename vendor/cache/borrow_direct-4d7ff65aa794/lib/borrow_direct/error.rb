module BorrowDirect
  class Error < StandardError
    attr_reader :bd_code

    def initialize(msg, bd_code = nil) 
      @bd_code = bd_code
      if @bd_code
        msg = "#{@bd_code}: #{msg}"
      end
      super(msg)      
    end
    
    # Different services use different error codes for 'invalid aid'
    # Not sure we can actually catch them all, but we'll try. 
    def self.invalid_aid_code?(bd_code)
      ["PUBFI003", "PUBRI002"].include?(bd_code)
    end    
  end

  class HttpError < Error ; end

  class HttpTimeoutError < HttpError
    attr_reader :timeout
    def initialize(msg, timeout=nil)
      @timeout = timeout
      super(msg)
    end
  end

  class InvalidAidError < Error
    attr_reader :aid
    def initialize(msg, bd_code = nil, aid = nil)
      msg += " (aid: #{aid})" if aid
      super(msg, bd_code)
      @aid = aid
    end
  end


end
