Then /^I should see a facet called '(.*?)'$/ do |facet|
    within('div.facets') do
	page.should have_content(facet)
    end
end
Then /^I should not see a facet called '(.*?)'$/ do |facet|
  within('div.facets') do
    page.should_not have_content(facet)
  end
end
#Then /^I (should|should not) see a facet called '(.*?)'$/ do |yesno,facet|
#  if (yesno == 'should')
#    within('div.facets') do
#	page.should have_content(facet)
#    end
#  else
#    within('div.facets') do
#	page.should_not have_content(facet)
#    end
#  end
#end

Then /^the '(.*?)' facet (should|should not) be open$/ do |facet, yesno|
  #TODO: Not sure how to test this
  facet.downcase!
  facet = facet_to(facet)
  within('div.facets') do

  	if (facet == 'blacklight-pub_date_facet')
  	  if (yesno == 'should')
	   	page.should have_css("div.#{facet} div.limit_content", :visible => true)
	  else
	 	page.should have_css("div.#{facet} div.limit_content", :visible => false)
  	  end

  	else
  	  if (yesno == 'should')
	   	page.should have_css("div.#{facet} ul", :visible => true)
	  else
	 	page.should have_css("div.#{facet} ul", :visible => false)
	  end
	end
  end
  # within('div.facets') do

  # end
end

Then("the count for category {string} facet {string} should be {string}") do |category, facet, count|
	category.downcase!
	category = facet_to(category)
	within ("div.#{category}") do
		li = find('.facet-select', :text => facet).first(:xpath, ".//..").first(:xpath, ".//..")
		expect(li.find('.facet-count')).to have_content(count)
	end
end

Then("I choose category {string} facet {string}") do |category, facet|
	category.downcase!
	category = facet_to(category)
	within ("div.#{category}") do
		find('.facet-select', :text => facet).click
	end
end

Then("I choose category {string} link {string}") do |category, facet|
	category.downcase!
	category = facet_to(category)
	within ("div.#{category}") do
		click_link(facet)
	end
end
