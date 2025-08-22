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

    @all_search
    @history
    Scenario: Clicking a BASIC saved search does not create a duplicate entry
      Given I am on the home page
      When I fill in the search box with 'biology'
      And I press 'search'
      Then click on first link "Search History"
      And I should see the text 'Your recent searches'
      And there should be 1 items in the Search History
      # Re-run the initial saved search from history
      Then click on first link "biology"
      # Return to history; entry count should remain 1
      Then click on first link "Search History"
      And there should be 1 items in the Search History
      And I should see the text 'biology'


    @all_search
    @history
    Scenario: Clicking an ADVANCED saved search does not create a duplicate entry
      Given I am on the home page
      # Open Advanced Search and perform a multi-row query with filters & range
      Then click on first link "Advanced Search"
      When I fill in advanced row 1 with 'Batman' in field 'All Fields'
      And I choose operator 'AND' for row 1
      And I add an advanced row
      And I fill in advanced row 2 with 'Superman' in field 'All Fields'
      And I choose operator 'OR' for row 2
      And I select inclusive facet 'Language' values 'English, French'
      And I set the Publication Year range begin '1900' and end '1950'
      And I press 'Search'
      Then click on first link "Search History"
      And I should see the text 'Your recent searches'
      And there should be 1 items in the Search History
      # Re-run the initial advanced saved search from history
      Then click on first link "Batman"
      # Return to history; entry count should remain 1
      Then click on first link "Search History"
      And there should be 1 items in the Search History
      And I should see the text 'Batman'
      And I should see the text 'Superman'