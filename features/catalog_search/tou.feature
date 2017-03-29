Feature: TOU tests
  I want to make sure tou works
  I want our users to see the terms of use when they click on a terms of use link

  @databases
  Scenario: User goes to databases page
    When I literally go to databases
    Then I should see the label 'Anthropology'
    When I literally go to databases/subject/Anthropology 
    Then I should see the label 'Terms of Use'
    When I literally go to /databases/tou/5366869
    Then I should see the label 'Course'
  