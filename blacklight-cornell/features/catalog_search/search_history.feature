Feature: Search History list

	In order to see what searches I have performed 
	As a user
	I want to view a list of searches that i have performed 
        @all_search 
        @no_history
	Scenario: No History 
		Given I am on the home page
                Then click on first link "Search History"
                And I should see the text 'You have no search history.'

        @all_search 
        @history
	Scenario: See search history
		Given I am on the home page
		When I fill in the search box with 'biology'
		And I press 'search'
                Then click on first link "Search History"
                And I should see the text 'Your recent searches'
                And I should see the text 'biology'

        @all_search 
        @history
	Scenario: See search history for searches with only facets
		Given I am on the home page
		Then click on first link "Online"
                Then click on first link "Search History"
                And I should see the text 'Your recent searches'
                And I should see the text 'Online'