# encoding: utf-8
Feature: Results list

  In order to find items that I search for
  As a user
  I want to view a list of search results with various options.

  Background:
  @all_results_list
  @rss
  Scenario: Empty search
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
  @next
  Scenario: Search with results
    Given I am on the home page
    When I fill in the search box with 'the'
    And I press 'search'
    Then I should get results
    And I should see the text 'Request from Libraries Worldwide'
    Then click on first link "Next »"
    Then I should get results

  Scenario: Search with special characters
    Given I view the search results list for 'the /'
    Then I should get results

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

  # DISCOVERYACCESS-?
  @all_results_list
  @pub_info
  Scenario: As a user I can see the publication date, publisher and place of publication on one line in the item record view.
    Given I view the search results list for 'encyclopedia of islamic architecture'
    Then I should get results
    Then results should have a "pub_info" that looks sort of like "[Cairo] : Maktabat al-Dār al-ʻArabīyah lil-Kitāb, 1999"

  # DISCOVERYACCESS-134
  @all_results_list
  Scenario: As a user, I can see publication date, publisher and location in one line in items on the query results list.
    Given I view the search results list for 'Convexity and duality in optimization'
    Then I should get results
    And it should contain "pub_info" with value "Berlin ; New York : Springer-Verlag, c1985."

  # DISCOVERYACCESS-135
  @all_results_list
  @DISCOVERYACCESS-135
  Scenario: As a user, I can see the edition of an item in the query results list.
    Given I view the search results list for 'Birds of the Bahamas,'
    Then I should get results
    And it should contain "edition" with value "1st ed"

  # DISCOVERYACCESS-344
  @all_results_list
  @discoveryaccess-344
  Scenario: Remove spaces from call number queries in Blacklight
    Given I view the search results list for 'lc_callnum'='QH324.5    .B615'
    Then I should get results
    And it should have a "title" that looks sort of like "Biology"

  # DISCOVERYACCESS-2879
  @discoveryaccess-2879
  @all_results_list
  Scenario: Online links in search results should go to item view when there is more than one online link
    Given I view the search results list for 'journaltitle'='Dokumente zur Deutschlandpolitik'
    And I select 'Journal Title' from the 'search_field' drop-down
    And I press 'search'
    Then I should get results

  # DISCOVERYACCESS-1407
  @all_results_list
  @DISCOVERYACCESS-1407
  @availability
  @javascript
  Scenario: As a user, I can see order status for items on order, but not open orders .. continuing for serials
    Given I view the search results list for 'the Economist newspaper'
    Then I should get results
    And I should not see the text 'Order Information'

  # DISCOVERYACCESS-1407
  @all_results_list
  @DISCOVERYACCESS-1407
  @availability
  @javascript
  Scenario: As a user, I can see order status for items on order
    Given I view the search results list for '10 nam nhin lai  Le Van Hien.'
    Then I should get results
    And I should see the text 'On Order'

  @all_results_list
  @DISCOVERYACCESS-1673
  Scenario: Search with results, but then visit an alternate world, and an item view, make sure we do NOT show the alternate world
    Given I view the search results list for 'human rights'
    Then I should get results
    When I literally go to databases
    Then I request the item view for 10976407
    And I should not see the text 'catalog results'

  @all_results_list
  @next_facet
  @javascript
  Scenario: Search with results
    Given I view the search results list for 'We were feminists'
    Then I should get results
    Then I should see the text 'Click : '
    Then click on first link "Click : when we knew we were feminists"
    Then I should see the text 'edited by Courtney E. Martin and J. Courtney Sullivan.'
    And I should see the text 'Back to catalog results'
    Then click on first link "Next »"
    Then I should see the text "Now that we're men"
    Then click on first link "Back to catalog results"
    Then I should get results

  # Combinatorial Algorithms, Algorithmic Press
  @all_results_list
  @javascript
  Scenario: Perform an All field search with a call number
    Given I view the search results list for 'TL565 .N85 no.185'
    Then I should get results
    And I should see the label '1 result'

# TODO: Figure out how to wait for expected links without a hard-coded sleep; rerun multiple times
  @all_results_list
  @next_facet
  @javascript
  Scenario: Search with results,
    Given I view the search results list for 'title'='ocean'
    Then I should get results
    Then I should see the text 'Ocean thermal energy conversion'
    Then click on first link "Ocean thermal energy conversion"
    Then click on first link "Next »"
    Then click on first link "Previous"
    Then I should see the text 'Ocean thermal energy conversion'

  # Combinatorial Algorithms, Algorithmic Press
  # # the selected sort field is visible, the unselected is not visible,though present in the html.
  @all_results_list
  @javascript
  Scenario: Perform an call number search, and confirm that the search order has switched to 'sort by call number'
    Given I view the search results list for 'lc_callnum'='UA830 .B61 1983'
    Then I should get results
    Then I should not see the text 'relevance'
    Then I should see the text 'Sort by call number'

  @all_results_list
  Scenario: Search with results,
    Given I view the search results list for 'title'='ocean'
    Then I should get results
    And I should see the "fa-rss-square" class

  @all_results_list
  @DISCOVERYACCESS-4700
  @sticky_per_page_preference
  Scenario Outline: Seach results display per page preference applies to new search
    Given I view the search results list for 'the'
    And I select <count> items per page
    And I click on the first search result
    When I fill in the search box with 'ocean'
    And I press 'search'
    And the 'per_page' select list should default to '<count> per page'

    Examples:
      | count |
      | 20    |
      | 50    |
      | 100   |


  @all_results_list
  @DISCOVERYACCESS-4700
  @sticky_sort_preference
  Scenario Outline: Seach results display sort preference applies to new search
    Given I view the search results list for 'the'
    Then I should get results
    And I select the sort option '<sort_by>'
    And I click on the first search result
    When I fill in the search box with 'ocean'
    And I press 'search'
    And the 'sort' select list should default to 'Sort by <sort_by>'

    Examples:
      | sort_by         |
      | relevance       |
      | year descending |
      | year ascending  |
      | author A-Z      |
      | author Z-A      |
      | title A-Z       |
      | title Z-A       |
      | call number     |

  @javascript
  Scenario: I can't see more than 20,000 search results
    Given I am on the home page
    And I press 'search'
    And I navigate to a page that exceeds search results
    Then I should see the text 'Search limit exceeded. To view additional results, modify your search using the available filters.'
