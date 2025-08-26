# encoding: UTF-8
Feature: Browse search
  In order to get information about authorities
  As a user
  I want to search author and subject authority records

  @browse
  Scenario: View the browse home page
    Given I literally go to browse
    Then I should see the text 'Browse through an alphabetical'

  @browse
  Scenario: Search for an author
    Given I literally go to browse
        And I fill in the authorities search box with 'Heaney, Seamus'
        And I press 'search'
    Then I should see the label 'Heaney, Seamus, 1939-2013'
    Then click on first link "Author info"
    Then I should see the label 'Heaney, Seamus, 1939-2013'
    Then I should see the label 'Library Holdings'

  @browse
  Scenario: Search for a subject
    Given I literally go to browse
        And I fill in the authorities search box with 'Wizards > Juvenile fiction'
        And I select 'Subject Browse (A-Z)' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Wizards > Juvenile fiction'
    Then click on first link "Subject info"
    Then I should see the label 'Wizards > Juvenile fiction'
    Then I should see the label 'Library Holdings'

  @browse
  @browse_search_switch
  Scenario: Search for a subject and switch to catalog
    Given I literally go to browse
        And I fill in the authorities search box with 'china industrialization'
        And I select 'Subject' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label '转型、升级与创新 : 中国特色新型工业化的系统性研究'
 #   Then I should see the label 'China's Industrialization Process'
 #   Then click on link "China's Industrialization Process"

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Beethoven, Ludwig van, 1770-1827 | Fidelio (1805)'
        And I select 'Author (A-Z) Sorted By Name' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Beethoven, Ludwig van, 1770-1827 | Fidelio (1805)'
    Then click on first link "Beethoven, Ludwig van, 1770-1827"
    Then I should see the label 'Beethoven, Ludwig van, 1770-1827'
    Then click on first link "Beethoven, Ludwig van, 1770-1827"
    And I should get 3 results
    # Then I should see the label '1 - 20 of'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Martin, Courtney E.'
        And I select 'Author (A-Z) Sorted By Name' from the 'browse_type' drop-down
        And I press 'search'
        Then I should see the label 'Martin, Courtney E.'
        Then click on first link "Martin, Courtney E."
        And I should get results
        Then I should see the label '3 catalog results'

  @browse
  Scenario: Browse author-title combinations and view heading details
    Given I literally go to browse
      And I fill in the authorities search box with 'McKenna, Maryn'
      And I select 'Author (A-Z) Sorted By Title' from the 'browse_type' drop-down
      And I press 'search'
    Then I should see the label 'McKenna, Maryn. | Big chicken'
    Then click on first link "Author-Title info"
    Then I should see the label 'McKenna, Maryn. | Big chicken'
      And I should see the label 'Library Holdings'
      And it should have link "Back to list" with value "/browse?authq=McKenna%2C+Maryn.+%7C+Big+chicken&browse_type=Author-Title&start=0"

  @browse
  @call-number-browse
  @DISCOVERYACCESS-4659
  Scenario: Search for LPs
    Given I literally go to browse
      And I fill in the authorities search box with 'LP'
      And I select 'Call Number Browse' from the 'browse_type' drop-down
      And I press 'search'
    Then I should see the label 'Whipped cream & other delights'
    Then click on first link "Sweet hands"
    Then I should see the label 'Dark lady'


  @browse
  @call-number-browse
  @call-number-browse-locations
  @DISCOVERYACCESS-4659
  Scenario: Search for call number LO in different locations
    Given I literally go to browse
      And I fill in the authorities search box with 'LO'
      And I select 'Call Number Browse' from the 'browse_type' drop-down
      And I press 'search'
    Then I should see the label 'Browse "LO" in call numbers'
    And call number 'P95 .P674 2012' should be available in 'Olin Library'
    And call number 'N3 .Z478' should be available in 'Mui Ho Fine Arts Library'
    And call number 'N5300 .A783' should be available in 'Online'
    And call number 'NC1766.J3 Y65 2006' should be available in 'Kroch Asia Collections'
    And call number 'ML419.G66 G67 2018' should be available in 'Cox Library of Music and Dance'
    And call number 'N3 .Z478' should be available in 'Library Annex'

  @browse
  @call-number-browse
  @call-number-browse-navigation
  @DISCOVERYACCESS-4659
  Scenario Outline: Search for call number LO in different locations
    Given I literally go to browse
      And I fill in the authorities search box with 'AC'
      And I select 'Call Number Browse' from the 'browse_type' drop-down
      And I press 'search'
#      And I click a link with text 'Music Library' within 'location-filter-dropdown'
#    Then I should see the label 'Going places'
    Then I should see the label 'The cheese and the worms'
      And I click '<go>' in the first page navigator
      And I click '<back>' in the first page navigator
    Then I should see the label 'The cheese and the worms'
      And I click '<go>' in the last page navigator
      And I click '<back>' in the last page navigator
    Then I should see the label 'The cheese and the worms'


  Examples:
  | go | back |
  | Next | Previous |
#  | « Previous | Next »  |

  @browse
  @call-number-browse
  @call-number-browse-navigate-switch-locations
  @DISCOVERYACCESS-4659
  Scenario: Switch locations after navigation
    Given I literally go to browse
      And I fill in the authorities search box with 'LO'
      And I select 'Call Number Browse' from the 'browse_type' drop-down
      And I press 'search'
#      And I click a link with text 'Music Library' within 'location-filter-dropdown'
#    Then I should see the label 'Going places'
#      And I click 'Next' in the first page navigator
#      And I click a link with text 'ILR Library' within 'location-filter-dropdown'
#    Then I should see the label 'Pins and needles : an oral history'
#

  @browse
  @DISCOVERYACCESS-7221
  Scenario Outline: Browse result counts should match catalog counts
    Given I literally go to browse
      And I fill in the authorities search box with '<search>'
      And I select '<browse>' from the 'browse_type' drop-down
      And I press 'search'
      Then I should be on 'the browse page'
      And the first browse heading '<heading>' should show '<count>' titles
      And click on first link "<heading>"
      Then I should get <count> results

  Examples:
      | search | browse | heading | count |
      | Rowling | Author (A-Z) Sorted By Name | Rowling, J. K. | 8 |
      | China | Subject Browse (A-Z) | China | 4 |
      | Wizards > Juvenile fiction | Subject Browse (A-Z) | Wizards > Juvenile fiction | 7 |
