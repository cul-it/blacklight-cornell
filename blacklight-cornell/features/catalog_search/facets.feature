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
	Scenario Outline: Facet counts in search for everything special
		Given I am on the home page
		And I search for everything
		And I choose category '<category>' link '<facet>'
		Then I should get <count> results

	Examples:
		| category | facet | count |
		| Publication Year | [Missing] | 5 |
		| Library Location | Lab of Ornithology | 1 |
		| Call Number | A - General | 8 |

	@DISCOVERYACCESS-7855
	Scenario Outline: Handling valid Publication Year date ranges
		Given I am on the home page
		And I search for everything
		Then I limit the publication year from <begin> to <end>
		Then I should get <count> results
		And I should not see 'Publication Year: Please enter'

	Examples:
		| begin | end | count |
		| 1600 | 2010 | 187 |
		| 1910 | 1950 | 24 |

	@DISCOVERYACCESS-7855
	Scenario Outline: Handling invalid Publication Year date ranges
		Given I am on the home page
		And I search for everything
		Then I limit the publication year from <begin> to <end>
		And I should see 'Publication Year: Please enter'

	Examples:
		| begin | end | count |
		| nil | 2010 | 187 |
		| 1910 | nil | 24 |
		| 1966 | 1800 | 2 |

	@DACCESS-215
	Scenario: Publication Year facet should engage when there is no query
		Given I open the 'Language' facet and choose 'English'
		And I also open the 'Format' facet and choose 'Book'
		And I also open the 'Access' facet and choose 'At the Library'
		And I limit the publication year from 2001 to 2018
		Then I should have about 29 results

	@DISCOVERYACCESS-7869
	Scenario Outline: Each facet should have it's own Facet page
		Given I visit the facet page for '<facet>'
		Then I should not see 'NoMethodError'
		And I should see '<facet_label>'

	Examples:
		| facet | facet_label | works |
		| online | Access | yes |
		| format | Format | yes |
		| author_facet | Author, etc. | x |
		| pub_date_facet | Publication Year | x |
		| workid_facet | Work | x |
		| language_facet | Language | yes |
		| fast_topic_facet | Subject | x |
		| fast_geo_facet | Subject: Region | x |
		| fast_era_facet | Subject: Era | x |
		| fast_genre_facet | Genre | x |
		| subject_content_facet | Fiction/Non-Fiction | x |
		| lc_alpha_facet | Call Number | x |
		| location | Library Location | yes |
		| hierarchy_facet | Hierarchy Facet | yes |
		| authortitle_facet | Author-Title | x |
		| lc_callnum_facet | Call Number | x |
		| collection | Collection | x |
		# wip | acquired_dt_query | Date Acquired | yes |

Scenario: Filtering searches by facets that are not available in the public ui
	When I literally go to ?f[availability_facet][]=Checked%20out
	Then I should get 10 results

Scenario: Searching multiple times retains the previous search session's facets
  When I literally go to ?boolean_row%5B1%5D=AND&f_inclusive%5Bformat%5D%5B%5D=Book&f_inclusive%5Bformat%5D%5B%5D=Journal%2FPeriodical&f_inclusive%5Blanguage_facet%5D%5B%5D=English&f_inclusive%5Blanguage_facet%5D%5B%5D=French&op_row%5B%5D=AND&op_row%5B%5D=AND&q=&q_row%5B%5D=Canada&q_row%5B%5D=&range%5Bpub_date_facet%5D%5Bbegin%5D=1960&range%5Bpub_date_facet%5D%5Bend%5D=2000&search_field=advanced&search_field_row%5B%5D=all_fields&search_field_row%5B%5D=all_fields
  Then I should get results
  And it should contain filter "All Fields" with value "Canada"
  And it should contain filter "Format" with value "Book OR Journal/Periodical"
  And it should contain filter "Language" with value "English OR French"
  And I should see the label 'Modify advanced search'
  And click on first link "Algebras and orders"
  Then I should see the label 'Algebras and orders'
  And I fill in the search box with 'beef'
  And I press 'search'
  Then I should get results
  And it should contain filter "All Fields" with value "beef"
  And it should contain filter "Format" with value "Book OR Journal/Periodical"
  And it should contain filter "Language" with value "English OR French"
  And I should not see the label 'Modify advanced search'
  And I fill in the search box with 'law'
  And I press 'search'
  Then I should get results
  And it should contain filter "All Fields" with value "law"
  And it should contain filter "Format" with value "Book OR Journal/Periodical"
  And it should contain filter "Language" with value "English OR French"
  And I should not see the label 'Modify advanced search'
