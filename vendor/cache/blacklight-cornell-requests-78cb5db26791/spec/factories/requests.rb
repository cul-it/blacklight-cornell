#require 'faker'

FactoryGirl.define do 

	factory :request, :class => "BlacklightCornellRequests::Request" do

		initialize_with { BlacklightCornellRequests::Request.new(5000000 + Random.rand(100000))}
		
	end
	
end