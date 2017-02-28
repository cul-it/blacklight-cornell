# encoding: utf8
Feature: Results list

	In order to find items that I search for
	As a user
	I want to view a list of search results with various options.

	Background:
        @all_results_list
        @rss
	Scenario: Empty search
                Given PENDING
		Given I am on the home page
		And I press 'search'

		# Tests copied from Blacklight gem code
		Then I should be on 'the catalog page'
		And I should get results
		And I should see an RSS discovery link
		And I should see an Atom discovery link
		And I should see OpenSearch response metadata tags
		And I should see the text 'Search History'

		# DISCOVERYACCESS-? Select # of items per page
		Then I should see the per_page select list
		And the 'per_page' select list should default to '20 per page'
		And the 'per_page' select list should have an option for '10 per page'
		And the 'per_page' select list should have an option for '50 per page'
		And the 'per_page' select list should have an option for '100 per page'

        @all_results_list
	Scenario: Search with no results
                Given PENDING
		Given I am on the home page
		When I fill in the search box with 'awfasdf acawfdfas'
		And I press 'search'
		#Then there should be 0 search results
		Then I should not get results

        @all_results_list
	@next
	Scenario: Search with results
		Given I am on the home page
		When I fill in the search box with 'biology'
		And I press 'search'
		Then I should get results
                Then click on first link "Next »"
		Then I should get results

        @all_results_list
	@next_facet
	Scenario: Search with results
		Given I am on the home page
		When I fill in the search box with 'biology'
		And I press 'search'
		Then I should get results
                Then click on first link "Next »"

        @all_results_list
	@getresults
	Scenario: Search with results
		Given I am on the home page
		When I fill in the search box with 'biology'
		And I press 'search'
		Then I should get results
		#Then there should be at least 1 search result

        @all_results_list
	Scenario: Search with results
		Given I am on the home page
		When I fill in the search box with 'biology'
		And I press 'search'
		Then I should get results

		# DISCOVERYACCESS-7
	#	And I should see 'Displaying all 6 items' or I should see 'Displaying items 1 - 6 of 6'

		# DISCOVERYACCESS-13 (tests for text description of format but not icon)
		And I should see each item format

		# DISCOVERYACCESS-8
		# TODO: this should test behavior, not just presence of search options
		And the 'sort' select list should have an option for 'relevance'
		And the 'sort' select list should have an option for 'year ascending'
		And the 'sort' select list should have an option for 'year descending'
		And the 'sort' select list should have an option for 'title A-Z'
		And the 'sort' select list should have an option for 'title Z-A'
		And the 'sort' select list should have an option for 'author A-Z'
		And the 'sort' select list should have an option for 'author Z-A'
    And the 'sort' select list should have an option for 'call number'

		# Users should be able to select items from the list. But see select_and_export.feature
		# for more details.
		And results should have a select checkbox
		And results should have a title field
  #/^it should have a "(.*?)" that looks sort of like "(.*?)"/
  # DISCOVERYACCESS-?
        @all_results_list
 @pub_info
  Scenario: As a user I can see the publication date, publisher and place of publication on one line in the item record view.
    Given I am on the home page
    And I fill in the search box with 'architecture'
    And I press 'search'
    Then I should get results
    Then results should have a "pub_info" that looks sort of like "Boca Raton, Florida"



	# TODO: following are additional tests from the Blacklight gem code. Implement or delete!

	 # Scenario: Submitting a Search with specific field selected
  #   When I am on the home page
  #   And I fill in "q" with "inmul"
  #   And I select "Title" from "search_field"
  #   And I press "search"
  #   Then I should be on "the catalog page"
  #   And I should see "You searched for:"
  #   And I should see "Title"
  #   And I should see "inmul"
  #   And I should see select list "select#search_field" with "Title" selected
  #   And I should see "1."
  #   And I should see "Displaying 1 item"

  # Scenario: Results Page Shows Vernacular (Linked 880) Fields
  #   Given I am on the home page
  #   And I fill in "q" with "history"
  #   When I press "search"
  #   Then I should see /次按驟變/

  # Scenario: Results Page Shows Call Numbers
  #   Given I am on the home page
  #   And I fill in "q" with "history"
  #   When I press "search"
  #   Then I should see "Call number:"
  #   And I should see "DK861.K3 V5"

  # Scenario: Results Page Has Sorting Available
  #   Given I am on the home page
  #   And I fill in "q" with "history"
  #   When I press "search"
  #   Then I should see select list "select#sort" with field labels "relevance, year, author, title"

  # Scenario: Can clear a search
  #   When I am on the home page
  #   And I fill in "q" with "history"
  #   And I press "search"
  #   Then I should be on "the catalog page"
  #   And I should see "You searched for:"
  #   And I should see "All Fields"
  #   And I should see "history"
  #   And the "q" field should contain "history"
  #   When I follow "start over"
  #   Then I should be on "the catalog page"
  #   And I should see "Welcome!"
  #   And the "q" field should not contain "history"

  # DISCOVERYACCESS-134
        @all_results_list
  Scenario: As a user, I can see publication date, publisher and location in one line in items on the query results list.
    Given I am on the home page
    When I fill in the search box with 'Convexity and duality in optimization'
    And I press 'search'
    Then I should get results
    And it should contain "pub_info" with value "Berlin ; New York : Springer-Verlag, c1985."

  # DISCOVERYACCESS-135
        @all_results_list
  @DISCOVERYACCESS-135
  Scenario: As a user, I can see the edition of an item in the query results list.
    Given I am on the home page
    When I fill in the search box with 'Birds of the Bahamas,'
    And I press 'search'
    Then I should get results
    And it should contain "edition" with value "1st ed"

  # DISCOVERYACCESS-344
  #/^it should have a "(.*?)" that looks sort of like "(.*?)"/
        @all_results_list
  @discoveryaccess-344
  Scenario: Remove spaces from call number queries in Blacklight
    Given I am on the home page
    When I fill in the search box with 'QH324.5    .B615'
    And I select 'Call Number' from the 'search_field' drop-down
    And I press 'search'
    Then I should get results
    And it should have a "title" that looks sort of like "Biology"

  # DISCOVERYACCESS-2879
  @discoveryaccess-2879
  Scenario: Online links in search results should go to item view when there is more than one online link
    Given I am on the home page
    When I fill in the search box with 'financial times'
    And I select 'Journal Title' from the 'search_field' drop-down
    And I press 'search'
    Then I should get results
    And it should have link "Online" with value "/catalog/5374340"



  # DISCOVERYACCESS-1407
        @all_results_list
  @DISCOVERYACCESS-1407
  @availability
  @javascript
  Scenario: As a user, I can see order status for items on order, but not open orders .. continuing for serials 
    Given I am on the home page
    When I fill in the search box with 'the Economist newspaper'
    And I press 'search'
    Then I should get results
    And I should not see the text 'Order Information'

  # DISCOVERYACCESS-1407
  # bibid - 9756432
        @all_results_list
  @DISCOVERYACCESS-1407
  @availability
  @javascript
  Scenario: As a user, I can see order status for items on order
    Given I am on the home page
    When I fill in the search box with '"Deconstructing the High line"'
    And I press 'search'
    And I sleep 4 seconds
    Then I should get results
    And I should see the text 'Order Information'

        @all_results_list
 @DISCOVERYACCESS-1673
 @catalogresults
 Scenario: Search with results, an item view, make sure we do show link to catalog results
   Given I am on the home page
   When I fill in the search box with 'Marvel Masterworks'
   And I press 'search'
   Then I should get results
   Then click on link "Marvel masterworks presents the X-men" 
   And I should see the text 'Back to catalog results'

        @all_results_list
 @DISCOVERYACCESS-1673
 Scenario: Search with results, but then visit an alternate world, and an item view, make sure we do NOT show the alternate world
   Given I am on the home page
   When I fill in the search box with 'Marvel Masterworks'
   And I press 'search'
   Then I should get results
   When I literally go to databases 
   Then I request the item view for 2083253
   And I should not see the text 'catalog results'

@DISCOVERYACCESS-2829
        @all_results_list
 Scenario: Search with results, make sure that there is a count associated with Libraries worldwide 
   Given I am on the home page
   When I fill in the search box with 'United States Cavalry'
   And I press 'search'
   Then I should see the text 'Request from Libraries Worldwide (23,'

@all_results_list
@next_facet
@javascript
  Scenario: Search with results, 
    Given I am on the home page
    When I fill in the search box with 'We were feminists'
    And I press 'search'
    Then I should get results
    Then I should see the text 'Click : '
    Then click on first link "Click : when we knew we were feminists" 
    Then I should see the text 'edited by Courtney E. Martin and J. Courtney Sullivan.'
    Then click on first link "Next »"
    Then I should see the text 'accidental feminist how Elizabeth Taylor raised our consciousness'

# Combinatorial Algorithms, Algorithmic Press
@all_results_list
@javascript
  Scenario: Perform an All field search with a call number
    Given I am on the home page
    When I fill in the search box with 'QA76.6 .C85 1972'
    And I press 'search'
    Then I should get results
    And I should see the label '1 result'

@all_results_list
@next_facet
@javascript
  Scenario: Search with results, 
    Given I am on the home page
    When I fill in the search box with 'cigarette prices'
    And I select 'Title' from the 'search_field' drop-down
    And I press 'search'
    Then I should get results
    And I sleep 4 seconds
    Then I should see the text 'Lighting Up and'
    Then click on first link "Lighting Up" 
    Then click on first link "Next »"
    Then I should see the text 'Cigarette Excise Taxation The Impact of Tax Structure'
    Then click on first link "Previous"
    Then I should see the text 'Lighting Up and'
