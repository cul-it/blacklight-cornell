@folio

Feature: check terms of use
    As a user
    I want to check the terms of use
    So that I can know what I can do with the content

    Scenario: Check old tou
        Given I literally go to /catalog/new_tou/14046327/12769773
        Then I should see 'Yes, reasonable portion.'
        And I should see 'OpenEdition'
