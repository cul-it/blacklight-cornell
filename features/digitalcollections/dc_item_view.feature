# encoding: UTF-8
Feature: Digital Collection View
  In order to get information about a Digital Collection
  As a user
  I want to see the list of the digital collections

  @digitalcollections
  Scenario: View a list of digital collections
  	Given I literally go to digitalcollections
  	Then I should see the label 'Collections digitized and curated by Cornell University Library.'

  @conzo
  @digitalcollections
  Scenario: Make sure list contains known collection
  	Given I literally go to digitalcollections
  	Then I should see the label 'Conzo'

  @hiphop
  @digitalcollections
  Scenario: Make sure list contains known collection
  	Given I literally go to digitalcollections
      And I fill in the search box with 'hip hop'
      And I press 'search'
      Then I should see the label 'Conzo'


