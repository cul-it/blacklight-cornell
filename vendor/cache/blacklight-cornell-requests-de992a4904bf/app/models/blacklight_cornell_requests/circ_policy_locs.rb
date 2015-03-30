module BlacklightCornellRequests
  class Circ_policy_locs < ActiveRecord::Base
    attr_accessible :CIRC_GROUP_ID,:PICKUP_LOCATION,:LOCATION_ID
    
    def readonly?
      false
    end
  end
end
