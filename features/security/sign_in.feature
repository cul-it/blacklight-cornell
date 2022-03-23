Feature: Protect certain application functions with log in requirements
    In order to use protected functions of the web application
    As a patron
    I expect to have to log in first

Scenario: I sign in from the home page
    Given I go to the home page
    Then I sign in
    Then show me the page
    And I click on the Sign in link
    Then where am I
    Then I should be required to sign in
