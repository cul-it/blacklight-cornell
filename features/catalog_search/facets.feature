Feature: Facets

	In order to refine my search results
	As a user
	I want to use facets for different search parameters.

	Background: 

	@homepage 
        @javascript
	Scenario: Viewing the home page
		Given I am on the home page
		Then I should see a facet called 'Access'
		And I should see a facet called 'Format'
		And I should see a facet called 'Author, etc.'
		And I should see a facet called 'Publication Year'
		And I should see a facet called 'Language'
		#And I should see a facet called 'Subject/Genre'
		And I should see a facet called 'Subject: Region'
		And I should see a facet called 'Subject: Era'
		And I should see a facet called 'Fiction/Non-Fiction'
		And I should see a facet called 'Library Location'
		And I should see a facet called 'Call Number'

		And the 'Access' facet should not be open
		# DISCOVERYACCESS-? 'Format' facet should always be open
		And the 'Format' facet should be open
		And the 'Author, etc.' facet should not be open
		And the 'Publication Year' facet should not be open
		And the 'Language' facet should not be open
		And the 'Subject/Genre' facet should not be open
		And the 'Subject: Region' facet should not be open
		And the 'Subject: Era' facet should not be open
		And the 'Fiction/Non-Fiction' facet should not be open
		And the 'Call Number' facet should not be open
		And the 'Library Location' facet should not be open

	@callnumber 
        @javascript
	Scenario: Viewing the home page
		Given I am on the home page
		And I should see a facet called 'Call Number'
