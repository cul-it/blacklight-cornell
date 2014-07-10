# This migration comes from blacklight_cornell_requests (originally 20130430193240)
class CreateBlacklightCornellRequestsRequests < ActiveRecord::Migration
  def change
    create_table :blacklight_cornell_requests_requests do |t|

      t.timestamps
    end
  end
end
