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
        And I fill in the search box with 'KMODDL'
        And I press 'search'
  	Then the link "KMODDL" should go to "/catalog/5146902"

  @DISCOVERYACCESS-2325
  @databases
  Scenario: Make sure list contains known collection
  	Given I literally go to databases/subject/Images
  	Then the link 'ARTstor' should go to 'http://resolver.library.cornell.edu/misc/5346517'

#  @DISCOVERYACCESS-2325
#  @databases
#  Scenario: Make sure list contains known collection
#  	Given I literally go to databases/subject/Images
#  	Then it should have link "ARTstor" with value "http://resolver.library.cornell.edu/misc/5346517"

  @databases
  @DISCOVERYACCESS-5764
  Scenario: Display the z-note information for databases
      Given I literally go to databases/title/b
      Then the link 'Beautiful birds : masterpieces from the Hill Ornithology Collection, Cornell University Library' should go to '/catalog/5458505'
      And the link 'Black Studies Center' should go to '/catalog/6946453'

  @databases
  @DISCOVERYACCESS-5764
  Scenario: Databases with multple links should link to the item view
      Given I literally go to databases/title/a
      And click on link "Artefacts Canada. Humanities"
      Then the link 'Artefacts Canada (Humanities.)' should go to 'http://resolver.library.cornell.edu/misc/aqv1252'
      And the link 'Canadian Heritage Information Network.' should go to 'https://www.canada.ca/en/heritage-information-network.html'

  @databases
  @DISCOVERYACCESS-5764
  Scenario: Databases with single links should link to the resource
      Given I literally go to databases/title/a
      Then the link "ARTstor" should go to "http://resolver.library.cornell.edu/misc/5346517"
  
  @databases
  @DACCESS-655
  Scenario: Make sure databases show page exists (for atom/rss feeds)
  	Given I literally go to databases/show/5146902
    Then should have title 'KMODDL'