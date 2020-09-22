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
  	Then I should see the label 'General Interest and Reference'

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

#  @DISCOVERYACCESS-2325
#  @databases
#  Scenario: Make sure list contains known collection
#  	Given I literally go to databases/subject/Images
#  	Then it should have link "ARTstor" with value "http://resolver.library.cornell.edu/misc/5346517"

  @databases
  @DISCOVERYACCESS-5764
  Scenario: Display the z-note information for databases
      Given I literally go to databases/title/b
      Then I should see the label 'British national bibliography'
      And I should see the label 'Catalogue has its own navigation buttons.'

  @databases
  @DISCOVERYACCESS-5764
  Scenario: Databases with multple links should link to the item view
      Given I literally go to databases/title/a
      And click on link "Artefacts Canada. Humanities"
      Then I should see the label 'Artefacts Canada (Humanities.)'
      And I should see the label 'Canadian Heritage Information Network.'

  @databases
  @DISCOVERYACCESS-5764
  Scenario: Databases with single links should link to the resource
      Given I literally go to databases/title/a
      Then the link "ARTstor" should go to "http://resolver.library.cornell.edu/misc/5346517"