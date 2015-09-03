module BlacklightCornellRequests
  module RequestHelper

  	# Time estimates are now delivered from the model in ranges (e.g., [1, 3])
  	# instead of integers. This function converts the range into a string for display
  	def delivery_estimate_display time_estimate

  		if time_estimate[0] == time_estimate[1]
  			pluralize(time_estimate[0], 'working day')
  		else
  			"#{time_estimate[0]} to #{time_estimate[1]} working days"
  		end
  	
  	end

  end
end
