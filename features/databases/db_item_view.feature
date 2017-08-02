# encoding: UTF-8
Feature: Databases List 
  In order to get information about a featured databases 
  As a user
  I want to see the list of the digital collections

  @databases
  Scenario: View a list of databases
  	Given I literally go to databases
  	Then I should see the label 'Search for top databases'

  @mla
  @databases
  Scenario: Make sure list contains known database 
  	Given I literally go to databases
  	Then I should see the label 'General Interest and Reference Biographies'

  @mla
  @databases
  Scenario: Make sure list contains known collection 
  	Given I literally go to databases
        And I fill in the search box with 'MLA'
        And I press 'search'
  	Then I should see the label 'MLA'

  @DISCOVERYACCESS-2325
  @databases
  Scenario: Make sure list contains known collection 
  	Given I literally go to databases/subject/Images
  	Then I should see the label 'ARTstor'

  @DISCOVERYACCESS-2325
  @databases
  Scenario: Make sure list contains known collection 
  	Given I literally go to databases/subject/Images
  	Then it should have link "ARTstor" with value "http://resolver.library.cornell.edu/misc/5346517" 

