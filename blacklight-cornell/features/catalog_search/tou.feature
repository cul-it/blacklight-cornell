Feature: TOU tests
  I want to make sure tou works
  I want our users to see the terms of use when they click on a terms of use link

  @databases
  Scenario: User goes to databases tou page
    When I literally go to databases
    Then I should see the label 'Anthropology'
    When I literally go to databases/subject/Anthropology
    Then I should see the label 'Terms of Use'
    When I literally go to /databases/tou/5861952
    Then I should see the label 'Authorized Users'


  Scenario: User goes to databases new_tou page
    When I literally go to databases
    When I literally go to databases/subject/Science%20and%20Technology
    Then I should see the label 'Terms of Use'
    When I literally go to /databases/new_tou/2929539/4478166
    Then I should see the label 'Authorized Users'
    Then I should see the label 'Is secure electronic ILL permitted?'
    Then I should see the label 'Is use in course reserves permitted?'
    Then I should see the label 'Can I download?'
    Then I should see the label 'Can I print?'
    Then I should see the label 'Is scholarly sharing allowed?'
    Then I should see the label 'Is walk-in access permitted?'
