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
  Scenario: Search for a subject and switch to catalog
    Given I literally go to browse
        And I fill in the authorities search box with 'china'
        And I select 'Subject' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'A companion to Chinese history'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Beethoven, Ludwig van, 1770-1827 | Fidelio'
        And I select 'Author (A-Z) Sorted By Title' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Beethoven, Ludwig van, 1770-1827. | Fidelio (1805)'
    Then click on link "Beethoven, Ludwig van, 1770-1827. | Fidelio (1805)"
    And I should get results
    Then I should see the label '1 - 6 of 6'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Hitchens, Bert'
        And I select 'Author (A-Z) Sorted By Title' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Hitchens, Bert. | End of the line'
    Then click on link "Hitchens, Bert. | End of the line"
    And I should get results
    Then I should see the label '1 result'

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
      And I click a link with text '<location>' within 'location-filter-dropdown'
    Then I should see the label '<title>'

  Examples:
  | location | title |
  | ✓ All | Publish! : the how-to magazine of desktop publishing |
  | Adelson Library | A distributional study of the reptiles of Maryland and the District of Columbia |
  | Africana Library | The collected works of Scott Joplin |
  | CISER Data Archive | Overall Real Property Tax Rates : Local Governments, 1981 |
  | Fine Arts Library | Sonic rebellion : music as resistance : Detroit 1967-2017 |
  | ILR Library | Mel Bay's immigrant songbook |
  | ILR Library Kheel Center | Labor's troubadour |
  | Kroch Library Asia | 往来物大系 / Ōraimono taikei |
  | Kroch Library Rare & Manuscripts | Joh. Amos Comenii Orbis sensualium picti pars prima -[secunda] ... Der sichtbaren Welt erster Theil -[anderer Theil] ... |
  | Law Library | Decisions of the Court of Appeals of Kentucky |
  | Library Annex | The hollow crown, the fall and foibles of the kings and queens of England |
  | Mann Library | Songs for the grange : set to music dedicated to the order of patrons of husbandry in the United States |
  | Mathematics Library | The acoustical foundations of music |
  | Music Library | Herb Alpert's Tijuana Brass. Vol. 2 |
  | Nestle Library | Real good grammar, too : a handbook for students and professionals |
  | Olin Library | Guardians of tradition, American schoolbooks of the nineteenth century |
  | Sage Hall Management Library | Recording industry in numbers |
  | Space Sciences Building | The book of the sky |
  | Uris Library | Bhangra dance hits |
  | Veterinary Library | Cornell '77 : the music, the myth, and the magnificence of the Grateful Dead's concert at Barton Hall |


