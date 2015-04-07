@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, and see results 

  Scenario: Search Page
    When I go to the catalog page
    Then I should see a search field
    And I should see a "Search" button
    And the page title should be "Cornell University Library Catalog"
    And I should see a stylesheet

