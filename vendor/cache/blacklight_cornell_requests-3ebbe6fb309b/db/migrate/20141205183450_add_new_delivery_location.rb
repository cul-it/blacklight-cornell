class AddNewDeliveryLocation < ActiveRecord::Migration
  def change
    # Add new row for NYC-CFEM program
    BlacklightCornellRequests::Circ_policy_locs.create :CIRC_GROUP_ID => 1, :LOCATION_ID => 250, :PICKUP_LOCATION => 'Y'
  end
end
