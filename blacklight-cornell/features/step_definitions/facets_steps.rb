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
	category_class = facet_to(category.downcase)
	within ("div.#{category_class}") do
		click_button(category)
		click_link(facet)
	end
end

Then("I limit the publication year from {int} to {int}") do |int, int2|
	within (find("form.range_pub_date_facet")) do
		fill_in 'range_pub_date_facet_begin', :with => int
		fill_in 'range_pub_date_facet_end', :with => int2
		first('input[type="submit"]').click
	end
end

def facet_label_to_field_name(label)
	blacklight_config = CatalogController.new.blacklight_config
	blacklight_config.facet_fields.find { |_, field_config| field_config.label == label }&.first
end

Then("I open the {string} facet and choose {string}") do |facet, choice|
	# choice must be on the first page of /catalog/facet/facet_label_to_field_name(facet)
	# this does NOT preserve the state of the other facets or the query
	field = facet_label_to_field_name(facet)
	visit facet_catalog_path(field)
	click_link(choice)
end

Then("I also open the {string} facet and choose {string}") do |facet, choice|
	# choice must be visible when the facet is openedhasit:
	tag = facet_to(facet.downcase)
	within('#facets') do
		facet = find("div.#{tag}")
		click_link(choice, :visible => false)
	end
end

Given("I visit the facet page for {string}") do |string|
	visit "/catalog/facet/#{string}"
end