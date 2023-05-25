# encoding: UTF-8
Feature: Javascript
  In order to run javascript
  As a user
  I want to be sure all the javascript code has loaded correctly with the page

@javascript
Scenario Outline: Page has loaded all javascript
    When I go to <page>
    Then all javascript has loaded

Examples:
    | page |
    | the home page  |
    | the catalog page |
    | the detail page for id 7981095 |
    | BookBag |
    | the search page |
    | the search everything page |
    | the search history page |
    | the single search results page |


@javascript
Scenario Outline: Page at path has loaded all javascript
    When I literally go to <path>
    Then all javascript has loaded

Examples:
    | path |
    | databases |
    | databases/subject/History |
    | credits |
    | myaccount/login |

@javascript
Scenario: Perform a search and see call number facet
    Given I am on the home page
    And I fill in the search box with 'ocean'
    And I press 'search'
    Then I should get results
    And all javascript has loaded
