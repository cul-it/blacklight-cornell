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
    #Then the 'search_field_advanced' drop-down should have an option for 'Journal title'
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
  Scenario: Search Page
    When I literally go to advanced 
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row1" with 'combinatorial algorithms'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'algorithmics'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'AND Publisher: algorithmics'

# Combinatorial Algorithms, Algorithmic Press 
  @adv_search
  @all_search
  @searchpage
  @javascript
  Scenario: Search Page
    When I literally go to advanced 
    And the page title should be "Advanced Search - Cornell University Library Catalog"
    And I should see a stylesheet
    And I fill in "q_row1" with 'combinatorial algorithms'
    And I select 'Title' from the 'search_field_advanced' drop-down
    Then I should select radio "OR"
    And I fill in "q_row2" with 'algorithmics'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 20 of'
    And I should see the label 'OR Publisher: algorithmics'

 @adv_search
 @all_search
 @callnumber
  @javascript
  Scenario: Perform an advanced search and see call number facet 
    When I literally go to advanced 
    And I fill in "q_row1" with 'biology'
    And I press 'advanced_search'
    Then I should get results
    And I should see a facet called 'Call Number' 

 @adv_search
 @all_search
 @publisher
 @javascript
  Scenario: Perform an advanced search by Publisher
    When I literally go to advanced 
    And I fill in "q_row1" with 'biology'
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Springer'
    And I select 'Publisher' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And it should contain filter "Publisher" with value "Springer"
    And I should see the label 'Springer'

 @adv_search
 @all_search
 @peabody
 @javascript
  Scenario: Perform an advanced search by author, as author see results 
    When I literally go to advanced 
    And I fill in "q_row1" with 'Peabody, William Bourn Oliver, 1799-1847'
    And I select 'Author, etc.' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'of 10'

# Combinatorial Algorithms, Algorithmic Press 
 @adv_search
 @all_search
 @peabody
 @javascript
  Scenario: Perform an advanced search by call number
    When I literally go to advanced 
    And I fill in "q_row1" with 'QA76.6 .C85 1972'
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
    And I fill in "q_row1" with 'journal of microbiology'
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
    And I fill in "q_row1" with '9781400068128'
    And I select 'ISBN/ISSN' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Frederick the Great'

#  
 @adv_search
 @all_search
 @notes
 @javascript
  Scenario: Perform an advanced search by notes 
    When I literally go to advanced 
    And I sleep 4 seconds
    And I fill in "q_row1" with 'English, German, Italian, Latin, or Portugese'
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
    And I fill in "q_row1" with 'English, German, Italian, Latin, or Portugese'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Notes' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Bibliotheca Instituti Historici'
    And I select 'phrase' from the 'op_row2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 8 of 8'

#  
 @adv_search
 @all_search
 @adv_donor
 @javascript
  Scenario: Perform an advanced search by donor 
    When I literally go to advanced 
    And I fill in "q_row1" with 'Jan Olsen'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Donor Name' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 19 of 19'
    And I should not see the label 'Modify advanced' 

#  
 @adv_search
 @all_search
 @adv_donor
 @javascript
  Scenario: Perform an advanced search by donor 
    When I literally go to advanced 
    And I fill in "q_row1" with 'Jan'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Donor Name' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Olsen'
    And I select 'all' from the 'op_row2' drop-down
    And I select 'Donor Name' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 19 of 19'
    And I should see the label 'Modify advanced' 

# Subject Molecular Biology and Recombinant DNA as Subjects 
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject 
    When I literally go to advanced 
    And I fill in "q_row1" with 'Molecular Biology'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Recombinant Dna'
    And I select 'all' from the 'op_row2' drop-down
    And I select 'Subject' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 12 of 12'

# Subject Molecular Biology and Recombinant DNA as Subjects 
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject 
    When I literally go to advanced 
    And I fill in "q_row1" with 'Molecular Biology'
    And I select 'phrase' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Recombinant Dna'
    And I select 'phrase' from the 'op_row2' drop-down
    And I select 'Subject' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 7 of 7'

# Subject Molecular Biology and Recombinant DNA as Subjects 
 @adv_search
 @all_search
 @adv_subject
 @javascript
  Scenario: Perform an advanced search by subject 
    When I literally go to advanced 
    And I fill in "q_row1" with 'Molecular Biology'
    And I select 'phrase' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Recombinant Dna'
    And I select 'phrase' from the 'op_row2' drop-down
    And I select 'Subject' from the 'search_field_advanced2' drop-down
    And click on link "add-row"
    And I sleep 4 seconds
    And I fill in "q_row3" with 'yeast'
    And I select 'phrase' from the 'op_row3' drop-down
    And I select 'Title' from the 'search_field_advanced3' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 result'
    And I should see the label 'Yeast molecular biology--recombinant DNA'

#  
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform an advanced search by place of publication 
    When I literally go to advanced 
    And I sleep 4 seconds
    And I fill in "q_row1" with 'yeast'
    And I select 'all' from the 'op_row' drop-down
    And I select 'Subject' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'Amsterdam'
    And I select 'all' from the 'op_row2' drop-down
    And I sleep 4 seconds
    And I select 'Place Of Publication' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label '1 - 8 of 8'
    And I should see the label 'Modify advanced' 

 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform a 2 row  advanced search by begins with Title 
    When I literally go to advanced 
    And I fill in "q_row1" with 'smoke some'
    And I select 'begins' from the 'op_row' drop-down
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I fill in "q_row2" with 'smoke some'
    And I select 'begins' from the 'op_row2' drop-down
    And I select 'Title' from the 'search_field_advanced2' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should see the label 'Modify advanced' 
    And I should see the label 'Smoke some kill' 
    And I should see the label '1 - 16 of 16'

 @begins_with
 @adv_search
 @all_search
 @adv_place
 @javascript
  Scenario: Perform a 1 row  advanced search by begins with Title 
    When I literally go to advanced 
    And I fill in "q_row1" with 'smoke some'
    And I select 'begins' from the 'op_row' drop-down
    And I select 'Title' from the 'search_field_advanced' drop-down
    And I press 'advanced_search'
    Then I should get results
    And I should not see the label 'Modify advanced' 
    And I should see the label 'Smoke some kill' 
    And I should see the label '1 - 16 of 16'


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
