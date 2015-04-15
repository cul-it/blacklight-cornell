Feature: Facets

	In order to refine my search results
	As a user
	I want to use facets for different search parameters.

	Background: 

	Scenario: Viewing the home page

		Given I am on the home page

		Then I should see a facet called 'Format'
		And I should see a facet called 'Publication Year'
		And I should see a facet called 'Subject/Genre'
		And I should see a facet called 'Language'
		And I should see a facet called 'Call Number'
		And I should see a facet called 'Subject: Region'

		# DISCOVERYACCESS-? 'Format' facet should always be open
		And the 'Format' facet should be open
		And the 'Publication Year' facet should not be open
		And the 'Subject/Genre' facet should not be open
		And the 'Language' facet should not be open
		And the 'Call Number' facet should not be open
		And the 'Subject: Region' facet should not be open
		And the 'Subject: Era' facet should not be open
		And the 'Location' facet should not be open
