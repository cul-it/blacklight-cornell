# encoding: UTF-8
@folio
Feature: Browse search
  In order to get information about availability
  As a user
  I want to check the status of a subset of catalog records with know availability

  @DISCOVERYACCESS-7118
  Scenario: View an available item
    Given I request the item view for 67466
    Then the availability icon should show a checkmark
    And availability should show status 'Available'

  @DISCOVERYACCESS-7118
  Scenario: View a recently returned item
    Given I request the item view for 8272732
    Then the first availability icon for "Olin Library" should show a checkmark
    And the first availability for "Olin Library" should show status 'Available'
    # no date available: And the first availability for "Olin Library" should show the date

  @DISCOVERYACCESS-7118
  Scenario: View a basic checked out item
    Given PENDING
    Given I request the item view for 1077314
    Then the availability icon should show a clock
    And availability should show status 'Checked out, due'
    And availability should show the due date

  @DISCOVERYACCESS-7118
  Scenario: View an unavailable item checked out for a short loan
    Given I request the item view for 1077314
    Then the first availability icon for 'Catherwood Library' should show a clock
    And the first availability for 'Catherwood Library' should show status 'Checked out, due'

  @DISCOVERYACCESS-7118
  Scenario: View an unavailable item that is missing
    Given I request the item view for 5729532
    Then the first availability icon for 'Uris Library' should show a clock
    And the first availability for 'Uris Library' should show status 'Missing'

  @DISCOVERYACCESS-7118
  Scenario: View an unavailable item that is in transit
    Given PENDING
    Given I request the item view for 1077314
    Then the first availability icon for 'ILR Library' should show a clock
    And the first availability for 'ILR Library' should show status 'In transit'

  @DISCOVERYACCESS-7118
  Scenario: View an unavailable item that is in a temporary location
    Given PENDING
    Given I request the item view for 38097
    Then the first availability icon for 'Library Annex' should show a checkmark
    And the first availability for 'Library Annex' should show status 'Available'
    And the availibility for 'Library Annex' should show a message 'v.2 Temporarily shelved in Asia Reserve'
    And the availibility for 'Library Annex' should show a message 'v.4 Temporarily shelved in Africana Library Reserve'


