@thumbnail
@javascript
Feature: Thumbnail images of the items are displayed when available
  In order to find documents
  As a user
  I want to see any available image of the document cover

@DISCOVERYACCESS-7501
Scenario Outline: Thumbnails are provided for some items with OCLC
    Given I am on the home page
    And I fill in the search box with 'music'
    And I press 'search'
    Then I should get results
    And I should see a thumbnail image for "<title>"

Examples:
    | title | id |
    | Stravinsky : a family chronicle : 1906-1940  | Value 2  |
    | Carly Simon's Romulus Hunt : a family opera ; vocal score | xx |
