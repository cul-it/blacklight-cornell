class CondCreateBlacklightCornellRequestsRequests < ActiveRecord::Migration
  def up 
    if !ActiveRecord::Base.connection.table_exists?  :blacklight_cornell_requests_requests
      create_table :blacklight_cornell_requests_requests do |t|
        t.timestamps
      end
    end
   end

    def down
      drop_table :blacklight_cornell_requests_requests do |t|
      end
    end
end
