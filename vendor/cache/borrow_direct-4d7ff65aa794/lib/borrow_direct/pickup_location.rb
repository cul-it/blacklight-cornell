module BorrowDirect
  # Returned from FindItem::Response.pickup_locations , contains
  # a #code and a #description .  #to_a returns a handy duple
  # suitable for passing to Rails options_for_select
  class PickupLocation
    attr_reader :response_hash
    def initialize(bd_hash)
      if bd_hash["PickupLocationCode"].empty? || bd_hash["PickupLocationDescription"].empty?
        raise ArgumentError, "PickupLocation requires a hash with PickupLocationCode and PickupLocationDescription, not `#{bd_hash}`"
      end

      @response_hash = bd_hash
    end

    def code
      @response_hash["PickupLocationCode"]
    end

    def description
      @response_hash["PickupLocationDescription"]
    end

    def to_h
      self.response_hash
    end

    # Handy for passing to Rails options_for_select
    def to_a
      [self.description, self.code]
    end
  end
end