# encoding: UTF-8
Feature: Browse info
  In order to get information about authorities
  As a user
  I want to view specific author and subject authority records

	@browse
	Scenario: View an author authority record for a personal name
	Given I request the personal name author item view for Jauss, Hans Robert
	Then I should see the text 'Total Works By:'

	@browse
	Scenario: View a subject authority record for a geographic name
	Given I request the geographic name subject item view for China > History
	Then I should see the text 'Total Works About:'

  @browse
  Scenario: View an author title authority record for a work
    Given I request the author title item view for Rowling, J. K. | Harry Potter and the goblet of fire
    Then I should see the text 'Works:'

 @browse @javascript
  Scenario: View an author title authority record for a work enhanced by Wikidata
    Given I request the author title item view for Beethoven, Ludwig van, 1770-1827. | Septet, clarinet, bassoon, horn, violin, viola, cello, double bass, op. 20, E♭ major
    Then I should see the text 'Works:'
    And I should see the text 'Instrumentation:'
    And I should see the text 'Opus:'
    And I should see the text 'Tonality:'
    And I should see the text '* From Wikidata'
