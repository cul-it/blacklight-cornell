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
        And I fill in the authorities search box with 'Dickens, Charles'
        And I press 'search'
    Then I should see the label 'Dickens, Charles, 1812-1870'

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
    Then click on link "Beethoven, Ludwig van, 1770-1827"
    Then I should see the label 'Beethoven, Ludwig van, 1770-1827'
    Then click on first link "Beethoven, Ludwig van, 1770-1827"
    And I should get results
    Then I should see the label '1 - 20 of'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Hitchens, Bert'
        And I select 'Author (A-Z) Sorted By Name' from the 'browse_type' drop-down
        And I press 'search'
        Then I should see the label 'Hitchens, Bert'
        Then click on first link "Hitchens, Bert"
#    	Then I should see the label 'Hitchens, Bert. | End of the line'
#    	Then click on link "Hitchens, Bert. | End of the line"
        And I should get results
        Then I should see the label '4 catalog results'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Hitchens, Bert'
        And I select 'Author (A-Z) Sorted By Name' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Hitchens, Bert'
    Then click on first link "Hitchens, Bert"
    Then I should see the label '1 - 4 of 4'

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
    #  And I click a link with text '<location>' within 'location-filter-dropdown'
    Then I should see the label 'Title'

  Examples:
  | location | title |
  | located in 2nd Floor Reading Room | Publish! : the how-to magazine of desktop publishing |
#  | London 4349 | A midsummer night's dream |
#  | Africana Library | The collected works of Scott Joplin |
#  | Bailey Hortorium | L'architecture comparée dans l'Inde et l'Extrême-Orient, par Henri Marchal |
#  | CISER Data Archive | Overall Real Property Tax Rates : Local Governments, 1981 |
#  | Fine Arts Library | Sonic rebellion : music as resistance : Detroit 1967-2017 |
#  | ILR Library | Mel Bay's immigrant songbook |
#  | ILR Library Kheel Center | Labor's troubadour |
#  | Kroch Library Asia | 往来物大系 / Ōraimono taikei |
#  | Kroch Library Rare & Manuscripts | Joh. Amos Comenii Orbis sensualium picti pars prima -[secunda] ... Der sichtbaren Welt erster Theil -[anderer Theil] ... |
#  | Law Library | Decisions of the Court of Appeals of Kentucky |
#  | Library Annex | The hollow crown, the fall and foibles of the kings and queens of England |
#  | Mann Library | Songs for the grange : set to music dedicated to the order of patrons of husbandry in the United States |
#  | Mathematics Library | The acoustical foundations of music |
#  | Music Library | Herb Alpert's Tijuana Brass. Vol. 2 |
#  | Nestle Library | Real good grammar, too : a handbook for students and professionals |
#  | Olin Library | Guardians of tradition, American schoolbooks of the nineteenth century |
#  | Sage Hall Management Library | Recording industry in numbers |
#  | Space Sciences Building | The book of the sky |
#  | Uris Library | Bhangra dance hits |
#  | Veterinary Library | Cornell '77 : the music, the myth, and the magnificence of the Grateful Dead's concert at Barton Hall |


  @browse
  @call-number-browse
  @call-number-browse-navigation
  @DISCOVERYACCESS-4659
  Scenario Outline: Search for call number LO in different locations
    Given I literally go to browse
      And I fill in the authorities search box with 'LO'
      And I select 'Call Number Browse' from the 'browse_type' drop-down
      And I press 'search'
#      And I click a link with text 'Music Library' within 'location-filter-dropdown'
#    Then I should see the label 'Going places'
    Then I should see the label 'Julius Caesar'
      And I click '<go>' in the first page navigator
      And I click '<back>' in the first page navigator
    Then I should see the label 'Julius Caesar'
      And I click '<go>' in the last page navigator
      And I click '<back>' in the last page navigator
    Then I should see the label 'Julius Caesar'


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

