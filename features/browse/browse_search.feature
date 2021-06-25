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

  @browse
  Scenario: Search for a subject
    Given I literally go to browse
        And I fill in the authorities search box with 'China > History'
        And I select 'Subject Browse (A-Z)' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'China > History'

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
  Scenario Outline: Search for call number LO in different locations
    Given I literally go to browse
      And I fill in the authorities search box with 'LO'
      And I select 'Call Number Browse' from the 'browse_type' drop-down
      And I press 'search'
    Then I should see the label 'Browse "LO" in call numbers'
    And call number '<callno>' should be available in '<location>'

  Examples:
  | callno | location |
  | PN45 .J41 1982 | Olin Library |
  | PR6058.E2 A6 2018 | Olin Library |
  | N5300 .A783 | Networked Resource |
  | Pamphlet J 1360 | Library Annex |
  | ML419.G66 G67 2018 |  Music Library (Lincoln Hall)  |
  | N3 .Z478 | Library Annex |

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

