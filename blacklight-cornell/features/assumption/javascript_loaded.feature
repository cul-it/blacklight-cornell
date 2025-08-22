# encoding: UTF-8
Feature: Javascript
  In order to run javascript
  As a user
  I want to be sure all the javascript code has loaded correctly with the page

@javascript
Scenario Outline: Page has loaded all javascript
    Given I enable ajax activity completion
    When I go to <page>
    Then I did not catch any javascript errors
    Then I disable ajax activity completion

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
    Given I enable ajax activity completion
    When I literally go to <path>
    Then I did not catch any javascript errors
    Then I disable ajax activity completion

Examples:
    | path |
    | databases |
    | databases/subject/History |
    | credits |
    # | myaccount/login |
    | catalog/6417953 |

@javascript
Scenario: Perform a search and see call number facet
    Given I enable ajax activity completion
    And I am on the home page
    And I fill in the search box with 'ocean'
    And I press 'search'
    Then I should get results
    And I did not catch any javascript errors
    Then I disable ajax activity completion
