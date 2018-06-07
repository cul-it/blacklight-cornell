# Given I am on the home page
#		When I fill in the search box with 'rope work'
#		And I press 'search'
#		Then I should get results    
#        Then I select the first 3 catalog results
#        When I view my selected items
#        Then I should be on 'the bookmarks page'
#        And there should be 3 items selected
#        Then I should see the text "Selected Items"
#        And I should not see the text "You have no selected items."
#        And click on link "Print"


require 'spec_helper'
# you have to configure a javascript driver properly in the spec_helper.
RSpec.feature "user saves bookmarks" do
  scenario "by selecting items from results list" , js: true do
   #VCR.use_cassette('feature/home', :record  => :new_episodes) do
   #VCR.use_cassette('feature/home') do
     visit '/' 
   #end
   fill_in 'q', :with => 'rope work'
   #VCR.use_cassette('feature/rope_work') do
     click_button('Search') 
   #end 
   select_check_boxes(2)
   visit '/bookmarks' 
   expect(page).to have_content("Selected Items")
   expect(page).to have_content("of 2")
  end

  def select_check_boxes(n)
   all_checkboxes = page.all(:css, "input.toggle_bookmark")
   for i in 0..n-1  do
     page.find(:xpath, all_checkboxes[i].path).set(true)
   end
  end

end

