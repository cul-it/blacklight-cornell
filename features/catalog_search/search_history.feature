Feature: Search History list

	In order to see what searches I have performed 
	As a user
	I want to view a list of searches that i have performed 
        @no_history
	Scenario: No History 
		Given I am on the home page
                Then click on first link "Search History"
                And I should see the text 'Your recent searches'

        @history
	Scenario: See search history
		Given I am on the home page
		When I fill in the search box with 'biology'
		And I press 'search'
                Then click on first link "Search History"
                And I should see the text 'Your recent searches'
                And I should see the text 'biology'
