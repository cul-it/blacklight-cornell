# encoding: utf-8
@all_search
@adv_search
@search
Feature: Search
  In order to find documents in an advanced search way
  As a user
  I want to enter terms, select terms for fields fields, and select number of results per page


  @all_search
  @adv_search
  @searchpage
  @javascript
  Scenario: Advanced Search Page search types
    When I literally go to advanced
    Then the 'search_field_advanced' drop-down should have an option for 'All Fields'
    Then the 'search_field_advanced' drop-down should have an option for 'Title'
    #Then the 'search_field_advanced' drop-down should have an option for 'Journal Title'
    Then the 'search_field_advanced' drop-down should have an option for 'Call Number'
    Then the 'search_field_advanced' drop-down should have an option for 'Publisher'
    Then the 'search_field_advanced' drop-down should have an option for 'Subject'
    Then the 'search_field_advanced' drop-down should have an option for 'Series'
    Then the 'search_field_advanced' drop-down should have an option for 'Donor'
    #Then the 'boolean_row[1]' radio should have an option for 'or'

  @adv_search
  @all_search
  @searchpage
  @javascript
  Scenario: Advanced search with title AND publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row1" with 'Encyclopedia of railroading'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'National Text Book Company'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    And I sleep 4 seconds
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'AND Publisher: National Text Book Company'

# Combinatorial Algorithms, Algorithmic Press
  @adv_search
  @all_search
  @search_title_or_publisher
  @searchpage
  @javascript
  Scenario: Advanced search with title OR publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row1" with 'Ocean thermal energy conversion'
    And I select 'Title' from the 'search_field_advanced' drop-down
    Then I should select radio "OR"
    And I fill in "q_row2" with 'Lexington Books'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 2 of'
    And I should see the label 'OR Publisher: Lexington Books'

# Combinatorial Algorithms, Algorithmic Press
  @adv_search
  @all_search
  @searchpage
  @javascript
  Scenario: Advanced search with title NOT publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row1" with 'Encyclopedia'
    And I select 'Title' from the 'search_field_advanced' drop-down
    Then I should select radio "NOT"
    And I fill in "q_row2" with 'springer'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    And I sleep 4 seconds
    Then I should get 3 results
    And I should see the label 'NOT Publisher: springer'

# Combinatorial Algorithms, Algorithmic Press
  @adv_search
  @all_search
  @searchpage
  @javascript
  @DISCOVERYACCESS-5739
  Scenario: Advanced search with title NOT publisher
    When I literally go to advanced
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row1" with 'Encyclopedia'
    And I select 'Title' from the 'search_field_advanced' drop-down
    Then I should select radio "NOT"
    And I fill in "q_row2" with 'springer'
    And I select 'All Fields' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get 3 results

 @adv_search
 @all_search
 @callnumber
  @javascript
  Scenario: Perform an advanced search and see call number facet
    When I literally go to advanced
    And I fill in "q_row1" with 'Encyclopedia'
    And I press 'advanced_search'
    Then I should get results
    And I should see a facet called 'Call Number'

 @adv_search
 @all_search
 @publisher
 @javascript
  Scenario: Perform an advanced search by Publisher
    When I literally go to advanced
    And I fill in "q_row1" with 'Encyclopedia'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'National Text Book Company'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
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
    And I fill in "q_row1" with 'Heaney, Seamus, 1939-2013'
    And I select 'Author' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 #
 #@javascript
 # Scenario: Perform an advanced search by title with colon, colon should be ignored.
 #   When I literally go to advanced
 #   And I fill in "q_row1" with 'ethnoarchaeology:'
 #   And I select 'Title' from the 'search_field_advanced' drop-down
 #   And I press 'advanced_search'
 #   Then I should get results
 #   And I should see the label '1 - 20 of'

# Combinatorial Algorithms, Algorithmic Press
 @adv_search
 @all_search
 @peabody
 @javascript
  Scenario: Perform an advanced search by call number
    When I literally go to advanced
    And I fill in "q_row1" with 'TL565 .N85 no.185'
    And I select 'phrase' from the 'op_row' drop-down
    And I select 'Call Number' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

 @adv_search
 @all_search
 @journaltitle
  @javascript
  Scenario: Perform an advanced search by journaltitle
    When I literally go to advanced
    And I select 'Journal Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row1" with 'Dokumente zur Deutschlandpolitik'
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'of '

# Frederick the great, by TCW Blanning
 @adv_search
 @all_search
 @issnisbn
 @javascript
  Scenario: Perform an advanced search by isbn
    When I literally go to advanced
    And I sleep 4 seconds
    And I fill in "q_row1" with '9780571347155'
    And I select 'ISBN/ISSN' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label '100 poems'

#
 @adv_search
 @all_search
 @notes
 @javascript
  Scenario: Perform an advanced search by notes
    When I literally go to advanced
    And I sleep 4 seconds
    And I fill in "q_row1" with 'Prepared under the sponsorship of the Propulsion and Energetics Panel.'
    And I select 'phrase' from the 'op_row' drop-down
    And I select 'Notes' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

# purple rain: music
 @adv_search
 @all_search
 @issnisbn
 @javascript
  Scenario: Perform an advanced search by other number
    When I literally go to advanced
    And I sleep 4 seconds
    And I fill in "q_row1" with '075992511025'
    And I select 'Publisher Number/Other Identifier' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

# . Greek papyri from Montserrat (P.Monts.Roca IV) 2014
 @adv_search
 @all_search
 @series
 @javascript
  Scenario: Perform an advanced search by series
    When I literally go to advanced
    And I sleep 4 seconds
    And I fill in "q_row1" with 'Scripta Orientalia'
    And I select 'Series' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

#
 @adv_search
 @all_search
 @adv_notes
 @javascript
  Scenario: Perform an advanced search by notes
    When I literally go to advanced
    And I sleep 4 seconds
    And I fill in "q_row1" with 'Prepared under the sponsorship of the Propulsion and Energetics Panel.'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Notes' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'North Atlantic Treaty Organization'
    And I select 'phrase' from the 'op_row2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

#
 @adv_search
 @all_search
 @adv_donor
 @javascript
  Scenario: Perform an advanced search by donor
    When I literally go to advanced
    And I fill in "q_row1" with 'Class of 1957'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Donor Name' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get 2 results
    #And I should see the label '1 result'
    #And I should not see the label 'Modify advanced'

#
 @adv_search
 @all_search
 @adv_donor
 @javascript
  Scenario: Perform an advanced search by donor
    When I literally go to advanced
    And I fill in "q_row1" with '1957'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Donor Name' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Pumpelly'
    And I select 'all' from the 'op_row2' drop-down
    And I select 'Donor Name' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Modify advanced'

# Subject Molecular Biology and Recombinant DNA as Subjects
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject
    When I literally go to advanced
    And I fill in "q_row1" with 'Hales, John'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Imprints'
    And I select 'all' from the 'op_row2' drop-down
    And I select 'Subject' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

# Subject Molecular Biology and Recombinant DNA as Subjects
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject
    When I literally go to advanced
    And I fill in "q_row1" with 'Ocean thermal power plants'
    And I select 'phrase' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Maritime law'
    And I select 'phrase' from the 'op_row2' drop-down
    And I select 'Subject' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'

# Subject Molecular Biology and Recombinant DNA as Subjects
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject
    When I literally go to advanced
    And I fill in "q_row1" with 'Ocean thermal power plants'
    And I select 'phrase' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Maritime law'
    And I select 'phrase' from the 'op_row2' drop-down
    And I select 'Subject' from the 'search_field_advanced2' drop-down
    And click on link "add-row"
    And I sleep 4 seconds
    And I fill in "q_row3" with 'conversion'
    And I select 'phrase' from the 'op_row3' drop-down
    And I select 'Title' from the 'search_field_advanced3' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Ocean thermal energy conversion'

#  fungi, recombinant dna, any publisher
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by all fields, all fields, phrase, and publisher any
    When I literally go to advanced
    And I fill in "q_row1" with 'Ocean thermal power plants'
    And I select 'all' from the 'op_row' drop-down
    And I select 'All Fields' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Maritime law'
    And I select 'phrase' from the 'op_row2' drop-down
    And I select 'All Fields' from the 'search_field_advanced2' drop-down
    And click on link "add-row"
    And I sleep 4 seconds
    And I fill in "q_row3" with 'Lexington Books'
    And I select 'any' from the 'op_row3' drop-down
    And I select 'Publisher' from the 'search_field_advanced3' drop-down
    And I press 'advanced_search'
    Then I should get results
    #And I should see the label '1 result'
    #And I should see the label 'Yeast molecular biology--recombinant DNA'

#
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform an advanced search by place of publication
    When I literally go to advanced
    And I sleep 4 seconds
    And I fill in "q_row1" with 'Ocean'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Lexington'
    And I select 'all' from the 'op_row2' drop-down
    And I sleep 4 seconds
    And I select 'Place of Publication' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Modify advanced'

 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform a 2 row  advanced search by begins with Title
    When I literally go to advanced
    And I fill in "q_row1" with 'Indian Ocean'
    And I select 'begins' from the 'op_row' drop-down
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Indian Ocean'
    And I select 'begins' from the 'op_row2' drop-down
    And I select 'Title' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label 'Indian Ocean and regional security'
    And I should see the label '1 result'



 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform a 1 row  advanced search by begins with Title
    When I literally go to advanced
    And I fill in "q_row1" with 'Indian Ocean'
    And I select 'begins' from the 'op_row' drop-down
    And I select 'Title' from the 'search_field_advanced' drop-down
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
    And I fill in "q_row1" with 'socccer'
    And I fill in "q_row2" with 'encyclopedia'
    And I press 'advanced_search'
    Then I should not see the label 'searched'
    And I should see the label 'soccer'

 @all_search
 @adv_place
 @javascript
 @DISCOVERYACCESS-3350
  Scenario: Perform a 2 row  advanced search with a blank in one field.
    When I literally go to advanced
    And I fill in "q_row1" with ' '
    And I fill in "q_row2" with 'we were once'
    And click on link "add-row"
    And I sleep 4 seconds
    And I fill in "q_row3" with ' '
    And I press 'advanced_search'
    Then I should not see the label 'searched'

 @javascript
 @DISCOVERYACCESS-3350
  Scenario: Perform a 2 row  advanced search with a blank in one field.
    When I literally go to advanced
    And I fill in "q_row1" with ' '
    And I fill in "q_row2" with 'we were once'
    And I press 'advanced_search'
    Then I should not see the label 'searched'

 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 2 row  advanced search with Title, with percent that must be url encoded.
    When I literally go to advanced
    And I fill in "q_row1" with 'beef'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with '100%'
    And I select 'Title' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    Then it should have link "Title: beef" with value 'catalog?&q_row[]=100%25&boolean_row[1]=AND&op_row[]=AND&search_field_row[]=title&search_field=advanced&action=index&commit=Search'
    #Then it should have link "Title: beef" with value 'catalog?&q=100%25&search_field=title&action=index&commit=Search'
    #Then it should have link "Title: beef" with value 'catalog?&amp;q=100%&amp;search_field=title&amp;action=index&amp;commit=Search'
    Then I remove facet constraint "beef"


 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 2 row  advanced search with Title with percent that must be url encoded.
    When I literally go to advanced
    And I fill in "q_row1" with 'beef'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with '100%'
    And I select 'Title' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label 'Institutional meat purchase specifications for fresh beef'
    And I sleep 8 seconds
    Then click on first link "Institutional meat purchase specifications for fresh beef"
    And I should see the label 'Institutional meat purchase specifications for fresh beef'
    And I sleep 10 seconds
    Then click on first link "Next »"
    And I sleep 8 seconds
    And I should see the label 'A sea-fight'
    And I sleep 8 seconds
    Then click on first link "Previous"
    And I sleep 8 seconds
    And I should see the label 'Institutional meat purchase specifications for fresh beef'
    And I should see the label 'Back to catalog results'
    Then click on first link "Back to catalog results"
    And I sleep 8 seconds
    And I should see the label '1 - '
    Then I go to the search history page
    And I sleep 8 seconds
    And I should see the label 'Title: beef AND Title: 100%'
    Then click on first link "Title: beef AND Title: 100%"
    And I sleep 8 seconds
    And I should see the label '1 - '
    Then I remove facet constraint "beef"
    And I sleep 8 seconds
    And I should see the label '1 - 5 of'



 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 3 row  advanced search with embedded quotes.
    When I literally go to advanced
    And I fill in "q_row1" with 'Birds I have kept'
    And I select 'any' from the 'op_row' drop-down
    And I select 'All Fields' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'years “gone by” “full directions” successfully'
    And I select 'any' from the 'op_row2' drop-down
    And click on link "add-row"
    And I sleep 4 seconds
    And I select 'All Fields' from the 'search_field_advanced2' drop-down
    And I fill in "q_row3" with 'Cage birds'
    And I select 'any' from the 'op_row3' drop-down
    And I select 'All Fields' from the 'search_field_advanced3' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced'
    And I should see the label '1 result'

 # DISCOVERYACCESS3298
 @adv_search
 @all_search
 @adv_title_percent
 @javascript
  Scenario: Perform a 2 row  advanced search with Title, with percent that must be url encoded.
    When I literally go to advanced
    And I fill in "q_row1" with 'manual of the trees of north america (exclusive of mexico)'
    And I fill in "q_row2" with 'sargent, charles sprague'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results


 @adv_search
 @all_search
 @adv_place
 @javascript
 @allow_rescue
  Scenario: Perform a 1 row  advanced search by begins with Title
    When I literally go to advanced
    And I fill in "q_row1" with quoted 'An historical and critical account'
    And I select 'begins' from the 'op_row' drop-down
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
    And I fill in "q_row1" with 'Struktura filosofskogo'
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced search'
    Then click on first link "Book"
    Then click on first link "Modify advanced search"
    And I should see the label 'Add a row'
