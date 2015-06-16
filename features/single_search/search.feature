@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, and see results 

  Scenario: Search Page
    When I go to the search page
    Then I should see a search field
    And I should see a "#search-btn" button 
    And the page title should be "Cornell University Library Search"
    And I should see a stylesheet

