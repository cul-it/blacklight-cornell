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
        And I select 'Subject' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'China > History'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Beethoven, Ludwig van, 1770-1827 | Fidelio'
        And I select 'Author (sorted by title)' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Beethoven, Ludwig van, 1770-1827. | Fidelio (1805)'
    Then click on link "Beethoven, Ludwig van, 1770-1827. | Fidelio (1805)"
    And I should get results
    Then I should see the label '1 - 5 of 5'

  @browse
  Scenario: Search for author-title combination
    Given I literally go to browse
        And I fill in the authorities search box with 'Dick, George'
        And I select 'Author (sorted by title)' from the 'browse_type' drop-down
        And I press 'search'
    Then I should see the label 'Dick, George. | Immunological Aspects of Infectious Diseases'
    Then click on link "Dick, George. | Immunological Aspects of Infectious Diseases"
    And I should get results
    Then I should see the label '1 result'
