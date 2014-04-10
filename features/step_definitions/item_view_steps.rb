Given /^I request the item view for (.*?)$/ do |bibid|
  visit "/catalog/#{bibid}"
end

Given /^I request the item holdings view for (.*?)$/ do |bibid|
  visit "/backend/holdings/#{bibid}"
end

And /^click on link "(.*?)"$/ do |link|
  click_link link
end

Then /^it should contain "(.*?)" with value "(.*?)"/ do |field, author|
  page.should have_selector(field_to(field), :text => author)
end

Then /^it should have a "(.*?)" that looks sort of like "(.*?)"/ do |field, author|
  page.should have_selector(field_to(field), :text => author,:exact =>false)
end

Then /^I (should|should not) see the label '(.*?)'$/ do |yesno, label|
  if yesno == "should not"
	page.should_not have_content(label)
  else
  	page.should have_content(label)
  end
end

Then /^I (should|should not) see the label '(.*?)' And I should see the label '(.*?)'/ do |yesno, label,label2|
  if yesno == "should not"
	page.should_not have_content(label) and page.should have_content(label2)
  else
  	page.should have_content(label) and  page.should have_content(label2)
  end
end

Then /^I (should|should not) see the labels '(.*?)'$/ do |yesno, llist|
  labels = llist.split(',') 
  if yesno == "should not"
        labels.each do |label|
	  page.should_not have_content(label)
        end
  else
        labels.each do |label|
	  page.should have_content(label)
        end
  end
end
