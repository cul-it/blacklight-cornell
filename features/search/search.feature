@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, select fields, and select number of results per page

  Scenario: Search Page
    When I go to the catalog page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "Search" button
    # And I should not see the "startOverLink" element
    # And I should see "Welcome!"
    And the page title should be "Cornell University Library Catalog"
    And I should see a stylesheet

  Scenario: Search Page search types
    When I am on the home page
    Then the 'search_field' drop-down should have an option for 'All Fields'
    Then the 'search_field' drop-down should have an option for 'Title'
    Then the 'search_field' drop-down should have an option for 'Author/Creator'
    Then the 'search_field' drop-down should have an option for 'Call Number'
    Then the 'search_field' drop-down should have an option for 'Publisher'
    Then the 'search_field' drop-down should have an option for 'Subject'

  @publisher
  Scenario: Perform a search by Publisher
    Given I am on the home page
    And I select 'Publisher' from the 'search_field' drop-down
    And I fill in the search box with 'Springer'
    And I press 'search'
    Then I should get results
    And it should contain filter "Publisher" with value "Springer"
    And I should see the label 'Springer'

