@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, select fields, and select number of results per page

  @searchpage
  Scenario: Search Page
    When I go to the catalog page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "#search-btn" button 
    # And I should not see the "startOverLink" element
    # And I should see "Welcome!"
    And the page title should be "Cornell University Library Catalog"
    And I should see a stylesheet

  Scenario: Search Page search types
    When I am on the home page
    Then the 'search_field' drop-down should have an option for 'All Fields'
    Then the 'search_field' drop-down should have an option for 'Title'
    Then the 'search_field' drop-down should have an option for 'Author, etc.'
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

  @peabody
  Scenario: Perform a search by author, as author see results 
    Given I am on the home page
    And I fill in the search box with 'Peabody, William Bourn Oliver, 1799-1847'
    And I press 'search'
    Then I should get results
    And I should see the label 'of 11'

  @journaltitle
  Scenario: Perform a search by journaltitle 
    Given I am on the home page
    And I select 'Journal Title' from the 'search_field' drop-down
    And I fill in the search box with 'tetrahedron'
    And I press 'search'
    Then I should get results
    And I should see the label 'of '

  @peabody
  Scenario: Perform a search by author, as author see results 
    Given I am on the home page
    And I select 'Author, etc.' from the 'search_field' drop-down
    And I fill in the search box with 'Peabody, William Bourn Oliver, 1799-1847'
    And I press 'search'
    Then I should get results
    And I should see the label 'of 10'

  @search_availability_annotated_hobbit
  @availability
  @clock
  @javascript
  Scenario: Perform a search and see no avail icon 
    Given I am on the home page
    And I fill in the search box with 'Annotated hobbit'
    And I press 'search'
    Then I should get results
    And I should see the "fa-clock-o" class

  @utf8
  @javascript
  Scenario: Perform a search and see linked fields displayed
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with '"美国学者论美国中"'
    And I press 'search'
    Then I should get results
    And I should see the label 'Meiguo xue zhe lun Meiguo Zhongguo xue' 
    And I should see the label '美国学者论美国中国学' 

  @search_availability_title_professional_manager_multiple
  @multiple
  @availability
  @javascript
  Scenario: Perform a title search and see avail icon, avail at  multiple locations 
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with '"The Professional Manager"'
    And I press 'search'
    Then I should get results
    And I should see the "fa-check" class
    And I should see the label 'Multiple locations' 

  @search_availability_title_mission_etrangeres_missing
  @multiple
  @availability
  @javascript
  Scenario: Perform a title search and see avail icon, avail at  multiple locations 
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with 'Atlas des missions de la Société des Missions-Etrangère'
    And I press 'search'
    Then I should get results
    And I should see the "fa-check" class
    And I should see the label 'Olin Library Maps' 

  # bibid 846380 Tolkien, new critical perspectives
  #   edited by Neil D. Isaacs & Rose A. Zimbardo
  @search_availability_title_tolkien_critical
  @multiple
  @availability
  @javascript
  Scenario: Perform a title search and see avail icon, avail at  multiple locations 
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with 'Tolkien, new critical perspectives'
    And I press 'search'
    Then I should get results
    And I should see the "fa-clock-o" class
    And I should see the label 'Olin Library' 
