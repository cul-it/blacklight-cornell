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

    def parsed_special_delivery(params)

      unless params['program'].present? && params['program']['location_id'] > 0
        Rails.logger.warn("Special Delivery: unable to find delivery location code in #{params.inspect}")
        return {}
      end

      program = params['program']
      office_delivery = program['location_id'] == 224
      formatted_label = office_delivery ? "Office Delivery" : "Special Program Delivery"
      formatted_label += " (#{params['delivery_location']})"

      {
        fod:   office_delivery,
        code:  params['program']['location_id'],
        value: formatted_label
      }
    end

  end
end
