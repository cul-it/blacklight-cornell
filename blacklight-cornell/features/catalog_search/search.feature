 @all_search
@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, select fields, and select number of results per page

 @all_search
   @searchpage
  Scenario: Search Page
    When I go to the catalog page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "#search-btn" button
    And the page title should be "Cornell University Library Catalog"
    And I should see a stylesheet

  @all_search
  @searchpage_types
  Scenario: Search Page search types
    When I am on the home page
    Then the 'search_field' drop-down should have an option for 'All Fields'
    Then the 'search_field' drop-down should have an option for 'Title'
    Then the 'search_field' drop-down should have an option for 'Journal Title'
    Then the 'search_field' drop-down should have an option for 'Author Browse (A-Z) Sorted By Name'
    Then the 'search_field' drop-down should have an option for 'Author Browse (A-Z) Sorted By Title'
    Then the 'search_field' drop-down should have an option for 'Author'
    Then the 'search_field' drop-down should have an option for 'Subject'
    Then the 'search_field' drop-down should have an option for 'Call Number'
    Then the 'search_field' drop-down should have an option for 'Call Number Browse'
    Then the 'search_field' drop-down should have an option for 'Publisher'

 @all_search
   @callnumber
  Scenario: Perform a search and see call number facet
    Given I am on the home page
    And I fill in the search box with 'ocean'
    And I press 'search'
    Then I should get results
    And I should see a facet called 'Call Number'

 @all_search
   @callnumber
  Scenario: Perform a quoted call number search and see 1 result
    Given I am on the home page
    And I select 'Call Number' from the 'search_field' drop-down
    And I fill in the search box with '"DD257.4 .A51"'
    And I press 'search'
    Then I should get results
    And I should see the label '1 result'

#Make sure constraint box appears
   @all_search
   @publisher
  Scenario: Perform a search by Publisher
    Given I am on the home page
    And I select 'Publisher' from the 'search_field' drop-down
    And I fill in the search box with 'Lexington Books'
    And I press 'search'
    Then I should get results
    And it should contain filter "Publisher" with value "Lexington Books"
    And I should see the label 'Lexington Books'

   @all_search
   @author
  Scenario: Perform a search by Author
    Given I am on the home page
    And I select 'Author' from the 'search_field' drop-down
    And I fill in the search box with 'Desmaizeaux'
    And I press 'search'
    Then I should get results
    And it should contain filter "Author" with value "Desmaizeaux"
    And I should see the label 'Desmaizeaux'

  @all_search
  @author
 Scenario: Perform a search by Author Browse
   Given I am on the home page
   And I select 'Author Browse (A-Z) Sorted By Name' from the 'search_field' drop-down
   And I fill in the search box with 'Desmaizeaux'
   And I press 'search'
   Then I should see the label 'in author headings'

   @all_search
   @title
  Scenario: Perform a search by Title
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with '100 poems'
    And I press 'search'
    Then I should get results
    And it should contain filter "Title" with value "100 poems"
    And I should see the label '100 poems'

  # @all_search
  # @title
  #Scenario: Perform a search by Title with a colon
  #  Given I am on the home page
  #  And I select 'Title' from the 'search_field' drop-down
  #  And I fill in the search box with 'ethnoarchaeology:'
  #  And I press 'search'
  #  Then I should get results
  #  And I should see the label '1 - 20'

   @all_search
   @peabody
  Scenario: Perform a search by author, as author see results
    Given I am on the home page
    And I fill in the search box with 'Heaney, Seamus, 1939-2013'
    And I press 'search'
    Then I should get results
    And I should see the label '1 result'

 @all_search
   @journaltitle
  Scenario: Perform a search by journaltitle
    Given I am on the home page
    And I select 'Journal Title' from the 'search_field' drop-down
    And I fill in the search box with 'Human rights quarterly'
    And I press 'search'
    Then I should get results
    And I should see the label '1 result'

 @all_search
   @peabody
  Scenario: Perform a search by author, as author see results
    Given I am on the home page
    And I select 'Author' from the 'search_field' drop-down
    And I fill in the search box with 'Heaney, Seamus, 1939-2013'
    And I press 'search'
    Then I should get results
    And I should see the label '1 result'

 @all_search
   @search_availability_annotated_hobbit
   @availability
   @clock
   @javascript
   @wip
  Scenario: Perform a search and see no avail icon
    Given I am on the home page
    And I fill in the search box with 'Annotated hobbit'
    And I press 'search'
    Then I should get results
    And I should see the "fa-clock-o" class

 @all_search
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

 @all_search
   @search_availability_title_professional_manager_multiple
   @multiple
   @availability
   @javascript
  Scenario: Perform a title search and see avail icon, avail at  multiple locations
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with '"Human rights quarterly"'
    And I press 'search'
    Then I should get results
    And I should see the "fa-check" class
    And I should see the label 'Olin Library'

    #And I fill in the search box with 'Atlas des missions de la Société des Missions-Etrangère'
 @all_search
   @search_availability_title_mission_etrangeres_missing
   @multiple
   @availability
   @javascript
  Scenario: Perform a title search and see avail icon, avail at  multiple locations
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with 'Plan of Franklinville'
    And I press 'search'
    Then I should get results
    And I sleep 15 seconds
    And I should see the "fa-check" class
    And I should see the label 'Olin Library Maps'

  # bibid 846380 Tolkien, new critical perspectives
  #   edited by Neil D. Isaacs & Rose A. Zimbardo
 @all_search
   @search_availability_title_tolkien_critical
   @multiple
   @availability
   @javascript
  Scenario: Perform a title search and see not avail icon, avail at  multiple locations
    Given I am on the home page
    And I select 'Title' from the 'search_field' drop-down
    And I fill in the search box with 'A constitution for the socialist commonwealth of Great Britain'
    And I press 'search'
    And I sleep 1 seconds
    Then I should get results
    And I sleep 8 seconds
    And I should see the "fa-clock-o" class
    And I should see the label 'Catherwood Library'

  # @all_search
  # @DISCOVERYACCESS-5984
  # Scenario: Perform a librarian_view on an item known to have MARC record problems
  #  Given I request the item view for 7928197
  #  Then I should not see the "librarianLink" element
  #  And I literally go to /catalog/7928197/librarian_view
  #  Then I should see the text 'No MARC data found.'

  @all_search
  @DISCOVERYACCESS-7889
  Scenario Outline: Confirm that the librarian view is working
  Given I attempt the item view for <asset_id>
    And click on link "Librarian View"
    Then I should see "LEADER"
    And I should see "<marc>"

  Examples:
      | asset_id | marc |
      | 10635622  | LEADER 03494cam a2200517 i 4500 |
      | 10294079 | ‡a Beethoven, Ludwig van, ‡d 1770-1827, ‡e composer. |
      | 9330651 | ‡6 880-04 ‡a Kyŏnggi-do P'aju-si : ‡b Kimyŏngsa, ‡c 2016. |


  @all_search
  @DISCOVERYACCESS-5826
  Scenario Outline: The catalog should not return suppressed records
    When I am on the home page
    And I attempt the item view for <bibid>
    Then I should see "Sorry, you have requested a record that doesn't exist."
    And I should not see "<title>"

  Examples:
  | bibid | title |
  | 3051761 | Asia gas report |
  | 2940172 | Boletim de integração latino-americana |
  | 3828983 | International Series in Heating, Ventilation and Refrigeration |
  | 7588266 | Satan is real |

  @DISCOVERYACCESS-8225
  @javascript
  Scenario: Perform a search and see no avail icon
    Given I am on the home page
    And I fill in the search box with 'harry'
    And I press 'search'
    Then I should get results
    And the Search Articles & Full Text link url should contain 'u2yil2' but not 'proxy.library'

  @DACCESS-192
  Scenario: Quoted search should select items with adjacent terms
    Given I am on the home page
    And I fill in the search box with '"republic and empire"'
    And I press 'search'
    Then I should get results
    And I should see "Roman colonies in republic and empire"
    And I should not see "Ancient libraries"
  @DACCESS-192
  Scenario: Quoted search should select items with adjacent terms
    Given I am on the home page
    And I fill in the search box with '"republic and empire"'
    And I press 'search'
    Then I should get results
    And I should see "Roman colonies in republic and empire"
    And I should not see "Ancient libraries"
