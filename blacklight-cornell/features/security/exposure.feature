Feature: Exposure of Secrets

@DISCOVERYACCESS-8026
@javascript
Scenario: As a diligent application, I should not be displaying the address of a backend system
Given I enable the "production" environment
    And I am on the home page
    Then I should not see "Solr core:"
    Then I enable the "development" environment
    And I am on the home page
    Then I should not see "Solr core:"
    Then I enable the "test" environment
    And I am on the home page
    Then I should not see "Solr core:"
