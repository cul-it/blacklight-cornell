# encoding: utf-8
@all_search
@adv_search
@search
Feature: Search
  In order to find documents in an advanced search way
  As a user
  I want to enter terms, select terms for fields fields, and select number of results per page

  @adv_search
  @all_search
  @searchpage
  @javascript
  Scenario: Advanced search with title AND publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And the 'search_field_row0' drop-down should have an option for 'All Fields'
    And the 'search_field_row0' drop-down should have an option for 'Title'
    And the 'search_field_row0' drop-down should have an option for 'Journal Title'
    And the 'search_field_row0' drop-down should have an option for 'Call Number'
    And the 'search_field_row0' drop-down should have an option for 'Publisher'
    And the 'search_field_row0' drop-down should have an option for 'Subject'
    And the 'search_field_row0' drop-down should have an option for 'Series'
    And the 'search_field_row0' drop-down should have an option for 'Place of Publication'
    And the 'search_field_row0' drop-down should have an option for 'Donor/Provenance'
    And the 'boolean_row[1]' drop-down should have an option for 'OR'
    And I fill in "q_row0" with 'Encyclopedia of railroading'
    And I select 'Title' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'National Text Book Company'
    And I select 'Publisher' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'AND Publisher: National Text Book Company'
    And I should see a facet called 'Call Number'
    And I should see the label 'Modify advanced'

  @adv_search
  @all_search
  @search_title_or_publisher
  @searchpage
  @javascript
  Scenario: Advanced search with title OR publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row0" with 'Ocean thermal energy conversion'
    And I select 'Title' from the 'search_field_row0' drop-down
    Then I select 'OR' from the 'boolean_row\[1\]' drop-down
    And I fill in "q_row1" with 'Lexington Books'
    And I select 'Publisher' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 2 of'
    And I should see the label 'OR Publisher: Lexington Books'

  @adv_search
  @all_search
  @searchpage
  @javascript
  Scenario: Advanced search with title NOT publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row0" with 'Encyclopedia'
    And I select 'Title' from the 'search_field_row0' drop-down
    Then I select 'NOT' from the 'boolean_row\[1\]' drop-down
    And I fill in "q_row1" with 'springer'
    And I select 'Publisher' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get 3 results
    And I should see the label 'NOT Publisher: springer'

  @adv_search
  @all_search
  @searchpage
  @javascript
  @DISCOVERYACCESS-5739
  Scenario: Advanced search with title NOT all fields
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row0" with 'Encyclopedia'
    And I select 'Title' from the 'search_field_row0' drop-down
    Then I select 'NOT' from the 'boolean_row\[1\]' drop-down
    And I fill in "q_row1" with 'springer'
    And I select 'All Fields' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results

 @adv_search
 @all_search
 @publisher
 @javascript
  Scenario: Perform an advanced search by Publisher
    When I literally go to advanced
    And I fill in "q_row0" with 'Encyclopedia'
    And I select 'Title' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'National Text Book Company'
    And I select 'Publisher' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And it should contain filter "Publisher" with value "National Text Book Company"
    And I should see the label 'National Text Book Company'

 @adv_search
 @all_search
 @peabody
 @javascript
  Scenario: Perform an advanced search by author, as author see results
    When I literally go to advanced
    And I fill in "q_row0" with 'Heaney, Seamus, 1939-2013'
    And I select 'Author' from the 'search_field_row0' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @peabody
 @javascript
  Scenario: Perform an advanced search by call number
    When I literally go to advanced
    And I fill in "q_row0" with 'TL565 .N85 no.185'
    And I select 'phrase' from the 'op_row0' drop-down
    And I select 'Call Number' from the 'search_field_row0' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @journaltitle
  @javascript
  Scenario: Perform an advanced search by journaltitle
    When I literally go to advanced
    And I select 'Journal Title' from the 'search_field_row0' drop-down
    And I fill in "q_row0" with 'Dokumente zur Deutschlandpolitik'
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'of '

 @adv_search
 @all_search
 @issnisbn
 @javascript
  Scenario: Perform an advanced search by isbn
    When I literally go to advanced
    And I fill in "q_row0" with '9780571347155'
    And I select 'ISBN/ISSN' from the 'search_field_row0' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label '100 poems'

 @adv_search
 @all_search
 @issnisbn
 @javascript
  Scenario: Perform an advanced search by other number
    When I literally go to advanced
    And I fill in "q_row0" with '075992511025'
    And I select 'Publisher Number/Other Identifier' from the 'search_field_row0' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @series
 @javascript
  Scenario: Perform an advanced search by series
    When I literally go to advanced
    And I fill in "q_row0" with 'Scripta Orientalia'
    And I select 'Series' from the 'search_field_row0' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @adv_notes
 @javascript
  Scenario: Perform an advanced search by notes
    When I literally go to advanced
    And I fill in "q_row0" with '"Prepared under the sponsorship of the Propulsion and Energetics Panel."'
    And I select 'all' from the 'op_row0' drop-down
    And I select 'Notes' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'North Atlantic Treaty Organization'
    And I select 'phrase' from the 'op_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @adv_donor
 @javascript
  Scenario: Perform an advanced search by donor
    When I literally go to advanced
    And I fill in "q_row0" with '1957'
    And I select 'all' from the 'op_row0' drop-down
    And I select 'Donor/Provenance' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'Pumpelly'
    And I select 'all' from the 'op_row1' drop-down
    And I select 'Donor/Provenance' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Modify advanced'

 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject
    When I literally go to advanced
    And I fill in "q_row0" with 'Hales, John'
    And I select 'phrase' from the 'op_row0' drop-down
    And I select 'Subject' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'Imprints'
    And I select 'all' from the 'op_row1' drop-down
    And I select 'Subject' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject and title
    When I literally go to advanced
    And I fill in "q_row0" with 'Ocean thermal power plants'
    And I select 'phrase' from the 'op_row0' drop-down
    And I select 'Subject' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'Maritime law'
    And I select 'phrase' from the 'op_row1' drop-down
    And I select 'Subject' from the 'search_field_row1' drop-down
    And click on link "add-row"
    And I fill in "q_row2" with 'conversion'
    And I select 'phrase' from the 'op_row2' drop-down
    And I select 'Title' from the 'search_field_row2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Ocean thermal energy conversion'

 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by all fields, all fields, phrase, and publisher any
    When I literally go to advanced
    And I fill in "q_row0" with 'Ocean thermal power plants'
    And I select 'all' from the 'op_row0' drop-down
    And I select 'All Fields' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'Maritime law'
    And I select 'phrase' from the 'op_row1' drop-down
    And I select 'All Fields' from the 'search_field_row1' drop-down
    And click on link "add-row"
    And I fill in "q_row2" with 'Lexington Books'
    And I select 'any' from the 'op_row2' drop-down
    And I select 'Publisher' from the 'search_field_row2' drop-down
    And I press 'advanced_search'
    Then I should get results
    #And I should see the label '1 result'
    #And I should see the label 'Yeast molecular biology--recombinant DNA'

 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform an advanced search by place of publication
    When I literally go to advanced
    And I fill in "q_row0" with 'Ocean'
    And I select 'all' from the 'op_row0' drop-down
    And I select 'Subject' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'Lexington'
    And I select 'all' from the 'op_row1' drop-down
    And I select 'Place of Publication' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Modify advanced'

  @adv_search
  @all_search
  @adv_place
  @javascript
  Scenario: Perform an advanced search by place of publication
    When I literally go to advanced
    And I fill in "q_row0" with 'New York'
    And I select 'all' from the 'op_row0' drop-down
    And I select 'Place of Publication' from the 'search_field_row0' drop-down
    And I press 'advanced_search'
    Then I should get 41 results
    And I should see the "Place of Publication" facet constraint
    And click on first link "The basic practice of statistics"
    Then I should see the label 'The basic practice of statistics'
    Then click on first link "Back to catalog results"
    And I should get 41 results

 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform a 2 row  advanced search by begins with Title
    When I literally go to advanced
    And I fill in "q_row0" with 'Indian Ocean'
    And I select 'begins' from the 'op_row0' drop-down
    And I select 'Title' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'Indian Ocean'
    And I select 'begins' from the 'op_row1' drop-down
    And I select 'Title' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label 'Indian Ocean and regional security'
    And I should see the label '1 result'

 @wip
 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
 @DISCOVERYACCESS-1392
  Scenario: Perform a 2 row  advanced search with a spelling error
    When I literally go to advanced
    And I fill in "q_row0" with 'socccer'
    And I fill in "q_row1" with 'encyclopedia'
    And I press 'advanced_search'
    Then I should not see the label 'searched'
    And I should see the label 'soccer'

 @all_search
 @adv_place
 @javascript
 @DISCOVERYACCESS-3350
  Scenario: Perform a 2 row  advanced search with a blank in one field.
    When I literally go to advanced
    And I fill in "q_row0" with ' '
    And I fill in "q_row1" with 'we were once'
    And click on link "add-row"
    And I fill in "q_row2" with ' '
    And I press 'advanced_search'
    Then I should not see the label 'searched'

 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 2 row  advanced search with Title, with percent that must be url encoded.
    When I literally go to advanced
    And I fill in "q_row0" with 'beef'
    And I select 'Title' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with '100%'
    And I select 'Title' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    Then it should have link "Title: beef" with value '/catalog?action=index&advanced_query=yes&commit=Search&controller=catalog&op_row%5B%5D=AND&q=title+%3D+100%25&q_row%5B%5D=100%25&range%5Bpub_date_facet%5D%5Bbegin%5D=&range%5Bpub_date_facet%5D%5Bend%5D=&search_field=advanced&search_field_row%5B%5D=title&show_query=title+%3D+100%25&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&utf8=%E2%9C%93&y='
    Then I remove facet constraint "beef"

 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 2 row advanced search with Title with percent that must be url encoded.
    When I literally go to advanced
    And I fill in "q_row0" with 'beef'
    And I select 'Title' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with '100%'
    And I select 'Title' from the 'search_field_row1' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label 'Institutional meat purchase specifications for fresh beef'
    Then click on first link "Institutional meat purchase specifications for fresh beef"
    And I should see the label 'Institutional meat purchase specifications for fresh beef'
    Then click on first link "Next »"
    And I should see the label 'A sea-fight'
    Then click on first link "Previous"
    And I should see the label 'Institutional meat purchase specifications for fresh beef'
    And I should see the label 'Back to catalog results'
    Then click on first link "Back to catalog results"
    And I should see the label '1 - '
    Then I go to the search history page
    And I should see the label 'Title: All beef AND Title: All 100%'
    Then click on first link "Title: All beef AND Title: All 100%"
    And I should see the label '1 - '
    Then I remove facet constraint "beef"
    And I should see the label '1 - 6 of'

 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 3 row  advanced search with embedded quotes.
    When I literally go to advanced
    And I fill in "q_row0" with 'Birds I have kept'
    And I select 'any' from the 'op_row0' drop-down
    And I select 'All Fields' from the 'search_field_row0' drop-down
    And I fill in "q_row1" with 'years “gone by” “full directions” successfully'
    And I select 'any' from the 'op_row1' drop-down
    And click on link "add-row"
    And I select 'All Fields' from the 'search_field_row1' drop-down
    And I fill in "q_row2" with 'Cage birds'
    And I select 'any' from the 'op_row2' drop-down
    And I select 'All Fields' from the 'search_field_row2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label '2 catalog results'

 @adv_search
 @all_search
 @adv_place
 @javascript
 @allow_rescue
  Scenario: Perform a 1 row  advanced search by begins with Title
    When I literally go to advanced
    And I fill in "q_row0" with quoted 'An historical and critical account'
    And I select 'begins' from the 'op_row0' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label 'An historical and critical account of the life and writing of the ever-memorable Mr. John Hales ... being a specimen of an historical and critical English dictionary'

 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
 @allow_rescue
  Scenario: Perform a 1 row  advanced search by begins with Title
    When I literally go to advanced
    And I fill in "q_row0" with 'Struktura filosofskogo'
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced search'
    Then click on first link "Book"
    Then click on first link "Modify advanced search"
    And I should see the label 'Add a row'

@DISCOVERYACCESS-8225
Scenario: Looking for more? link for Articles & Full Text should not have proxy
    When I literally go to advanced
    And I fill in "q_row0" with 'harry'
    And I press 'advanced_search'
    Then I should get results
    And the Search Articles & Full Text link url should contain 'u2yil2' but not 'proxy.library'

@DACCESS-194
@javascript
Scenario: Try an advanced search with and advanced query
    Given PENDING
    When I literally go to advanced
    And click on link "add-row"
    And I use 'Barney Glover' with 'phrase' logic for field 'Author' on line 1 of advanced search
    And I select 'OR' from the boolean dropdown on line 2
    And I use 'Rachna Mataudul' with 'phrase' logic for field 'Author' on line 2 of advanced search
    And I select 'AND' from the boolean dropdown on line 3
    And I use 'Kluwer' with 'any' logic for field 'Publisher' on line 3 of advanced search
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Optimization and related topics'
    And I should see the label 'Tax Treaty Dispute Resolution : lessons from the Law of the Sea'

@DACCESS-174
@javascript
Scenario Outline: Testing And Or Not logic with separate Authors
    When I literally go to advanced
    And I use '<q1>' with 'all' logic for field '<field>' on line 1 of advanced search
    Then I select '<boolean>' from the boolean dropdown on line 2
    And I use '<q2>' with 'all' logic for field '<field>' on line 2 of advanced search
    And I press 'advanced_search'
    Then I should get <results> results

Examples:
  | boolean | results | field | q1 | q2 |
  | AND | 1 | Author | Simpson | Smith |
  | OR | 4 | Author | Simpson | Smith |
  | NOT | 0 | Author | Simpson | Smith |
  | NOT | 3 | Author | Smith | Simpson |
  | AND | 1 | All Fields | complete | fire |
  | NOT | 4 | All Fields | complete | fire |
  | AND | 1 | Title | 100 | match |
  | OR | 7 | Title | 100 | match |
  | NOT | 5 | Title | 100 | match |
  | NOT | 1 | Title | match | 100 |

@DACCESS-174
@javascript
Scenario Outline: Testing And Or Not logic with separate Authors
    Given PENDING
    When I literally go to advanced
    And I use '<q1>' with 'all' logic for field '<field>' on line 1 of advanced search
    Then I select '<boolean>' from the boolean dropdown on line 2
    And I use '<q2>' with 'all' logic for field '<field>' on line 2 of advanced search
    And I press 'advanced_search'
    Then I should get <results> results

Examples:
  | boolean | results | field | q1 | q2 |
  | OR | 9 | All Fields | complete | fire |
  | NOT | 8 | All fields | fire | complete |

@DACCESS-194
@javascript
Scenario: Try an advanced search with and advanced query
    Given PENDING
    When I literally go to advanced
    And click on link "add-row"
    And I use 'Barney Glover' with 'phrase' logic for field 'Author' on line 1 of advanced search
    And I select 'OR' from the boolean dropdown on line 2
    And I use 'Rachna Mataudul' with 'phrase' logic for field 'Author' on line 2 of advanced search
    And I select 'AND' from the boolean dropdown on line 3
    And I use 'Kluwer' with 'any' logic for field 'Publisher' on line 3 of advanced search
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Optimization and related topics'
    And I should see the label 'Tax Treaty Dispute Resolution : lessons from the Law of the Sea'

@DACCESS-174
@javascript
Scenario Outline: Testing And Or Not logic with separate Authors
    Given PENDING
    When I literally go to advanced
    And I use '<q1>' with 'all' logic for field '<field>' on line 1 of advanced search
    Then I select '<boolean>' from the boolean dropdown on line 2
    And I use '<q2>' with 'all' logic for field '<field>' on line 2 of advanced search
    And I press 'advanced_search'
    Then I should get <results> results

Examples:
  | boolean | results | field | q1 | q2 |
  | OR | 9 | All Fields | complete | fire |
  | NOT | 8 | All fields | fire | complete |

@DACCESS-313
Scenario Outline: Simple advanced search solr query matches regular search
  Given I am on the home page
    And I fill in the search box with '<search>'
    And I press 'search'
    Then the solr query should be '<solr_query>'
    When I literally go to advanced
    And I fill in "q_row0" with '<search>'
    And I press 'advanced_search'
    Then the solr query should be '(<solr_query>)'

Examples:
    | search | solr_query |
    | goblet  | ("goblet") OR phrase:"goblet" |
    | goblet of fire | ("goblet" AND "of" AND "fire") OR phrase:"goblet of fire" |
    | going fishing | ("going" AND "fishing") OR phrase:"going fishing" |
    | "going fishing" | (quoted:"going fishing") |
    | fishing | ("fishing") OR phrase:"fishing" |
    | a doll's house | ("a" AND "doll's" AND "house") OR phrase:"a doll's house" |
    | A "fish finder" going fishing offshore | (("A") OR phrase:"A") AND (quoted:"fish finder") AND (("going" AND "fishing" AND "offshore") OR phrase:"going fishing offshore") |

Scenario: Empty searches produce empty solr queries in advanced and simple search
  Given I am on the home page
    And I fill in the search box with ''
    And I press 'search'
    Then the solr query should be ''
    When I literally go to advanced
    And I fill in "q_row0" with ''
    And I press 'advanced_search'
    Then the solr query should be ''

@javascript
Scenario: I can filter advanced searches by facets
  When I literally go to advanced
  And I fill in "q_row0" with 'Canada'
  And I fill in "range_pub_date_facet_begin" with '1960'
  And I fill in "range_pub_date_facet_end" with '2000'
  And I should not see the text "French"
  And I press 'Language'
  And I should select checkbox "f_inclusive_language_facet_0"
  And I should select checkbox "f_inclusive_language_facet_2"
  And I should not see the text "Journal/Periodical"
  And I press 'Format'
  And I should select checkbox "f_inclusive_format_0"
  And I should select checkbox "f_inclusive_format_1"
  And I press 'advanced_search'
  Then I should get 2 results
  Then click on first link "International wildlife"
  Then I should see the label 'International wildlife'
  And I fill in the search box with 'wildlife'
  And I press 'search'
  Then I should get results


######################################------------------------------------------
##  JS Date Range Validation Tests  ##
######################################
@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: Valid 4-digit range enables search (no alerts)
  When I literally go to advanced
  And I fill in "range_pub_date_facet_begin" with '1960'
  And I fill in "range_pub_date_facet_end" with '2000'
  Then the date range alert should be hidden
  And the advanced search submit button should be enabled

@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: Single start without end shows error after blur and disables search
  When I literally go to advanced
  And I focus the start year field
  And I type '1999' into the focused field
  Then the date range alert should be hidden
  And the advanced search submit button should be enabled
  When Leave from the date range section of the form
  Then the date range alert should be visible with message 'Please enter an end date.'
  And the end year field should be invalid
  And the advanced search submit button should be disabled

@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: Single end without start shows error after blur and disables search
  When I literally go to advanced
  And I focus the end year field
  And I type '1999' into the focused field
  Then the date range alert should be hidden
  And the advanced search submit button should be enabled
  When Leave from the date range section of the form
  Then the date range alert should be visible with message 'Please enter a start date.'
  And the start year field should be invalid
  And the advanced search submit button should be disabled

@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: Partial year while focused does not show ordering error
  When I literally go to advanced
  And I fill in "range_pub_date_facet_begin" with '2000'
  And I focus the end year field
  And I type '300' into the focused field
  Then the date range alert should be hidden
  And the advanced search submit button should be enabled
  When Leave from the date range section of the form
  Then the date range alert should be visible with message 'Start date must be earlier than or equal to end date.'
  And the advanced search submit button should be disabled

@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: Negative years are accepted (BCE)
  When I literally go to advanced
  And I fill in "range_pub_date_facet_begin" with '-500'
  And I fill in "range_pub_date_facet_end" with '-100'
  Then the date range alert should be hidden
  And the advanced search submit button should be enabled

@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: 200 - 3 should trigger ordering error after blur
  When I literally go to advanced
  And I fill in "range_pub_date_facet_begin" with '200'
  And I fill in "range_pub_date_facet_end" with '3'
  When Leave from the date range section of the form
  Then the date range alert should be visible with message 'Start date must be earlier than or equal to end date.'
  And the advanced search submit button should be disabled

@adv_search
@all_search
@javascript
@pubyear_validation
Scenario: 500 - 50 should trigger ordering error after blur
  When I literally go to advanced
  And I fill in "range_pub_date_facet_begin" with '500'
  And I fill in "range_pub_date_facet_end" with '50'
  When Leave from the date range section of the form
  Then the date range alert should be visible with message 'Start date must be earlier than or equal to end date.'
  And the advanced search submit button should be disabled
