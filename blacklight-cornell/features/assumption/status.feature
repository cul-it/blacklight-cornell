Feature: Check Status Page

Scenario: Check Status Page
Given I go to the status page
Then I should not see 'ERROR'


Scenario: Check new tou
Given I literally go to /catalog/new_tou/14046327/12769773
Then I should see 'Yes, reasonable portion.'
And I should see 'OpenEdition'