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
		And I should not see a facet called 'Author, etc.'
		And I should not see a facet called 'Publication Year'
		And I should see a facet called 'Language'
		#And I should not see a facet called 'Subject/Genre'
		And I should not see a facet called 'Subject: Region'
		And I should not see a facet called 'Subject: Era'
		And I should not see a facet called 'Fiction/Non-Fiction'
		And I should see a facet called 'Library Location'
		And I should not see a facet called 'Call Number'
		And I should see only the first 10 Format facets

		And the 'Access' facet should not be open
		# DISCOVERYACCESS-? 'Format' facet should always be open
		And the 'Format' facet should be open
		And the 'Language' facet should not be open

	@homepage
	@nocallnumber
    @javascript
	Scenario: Viewing the home page
		Given I am on the home page
		And I should not see a facet called 'Call Number'

	@DISCOVERYACCESS-7221
	Scenario Outline: Facet counts in search for everything
		Given I am on the home page
		And I search for everything
		Then the count for category '<category>' facet '<facet>' should be '<count>'
		And I choose category '<category>' facet '<facet>'
		Then I should get <count> results

	Examples:
		| category | facet | count |
		| Access | At the Library  | 180  |
		| Format | Book | 165 |
		| Author, etc. | Rowling, J. K. | 8 |
		| Language | English | 168 |
		| Subject | Magic | 8 |
		| Subject: Region | United States | 25 |
		| Subject: Era | 1900 - 1999 | 5 |
		| Genre | Periodicals | 26 |
		| Fiction/Non-Fiction | Non-Fiction (books) | 135 |
		| Date Acquired | Since last year | 14 |


	@DISCOVERYACCESS-7221
	Scenario Outline: Facet counts in search for everything special
		Given I am on the home page
		And I search for everything
		And I choose category '<category>' link '<facet>'
		Then I should get <count> results

	Examples:
		| category | facet | count |
		| Publication Year | Unknown | 2 |
		| Library Location | Adelson Library | 2 |
		| Call Number | A - General | 8 |
