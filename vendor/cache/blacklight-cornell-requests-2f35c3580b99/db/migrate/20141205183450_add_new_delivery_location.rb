class AddNewDeliveryLocation < ActiveRecord::Migration
  def change
    # Add new row for NYC-CFEM program
    BlacklightCornellRequests::Circ_policy_locs.create :circ_group_id => 1, :location_id => 250, :pickup_location => 'Y'
  end
end
