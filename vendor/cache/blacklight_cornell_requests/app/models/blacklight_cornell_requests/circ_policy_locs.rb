module BlacklightCornellRequests
  class Circ_policy_locs < ActiveRecord::Base
    attr_accessible :circ_group_id,:pickup_location
    
    def readonly?
      true
    end
  end
end
