@DACCESS-311

Feature: Handle WorldCat links

Scenario: Handle numbers (oclc) link from worldcat to the library
    When I literally go to number/1026079593
    Then I should see "100 poems"

Scenario: Handle isbn link from worldcat to the library
    When I literally go to oclc/1026079593
    Then I should see "100 poems"

Scenario: Handle issn link from worldcat to the library
    When I literally go to isbnissn/9780571347155
    Then I should see "100 poems"