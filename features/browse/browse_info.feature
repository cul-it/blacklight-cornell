# encoding: UTF-8
Feature: Browse info
  In order to get information about authorities
  As a user
  I want to view specific author and subject authority records

  @browse
  Scenario: View an author authority record for a personal name
    Given I request the personal name author item view as Salter,%20Malcolm%20S.
    Then I should see the text 'Total Works By:'

  @browse
  Scenario: View a subject authority record for a geographic name
    Given I request the geographic name subject item view as New%20York%20(Colony)
    Then I should see the text 'Total Works About:'

  @browse
  Scenario: View an author title authority record for a work
    Given I request the author title item view as Rowling,%20J.%20K.%20%7C%20Harry%20Potter%20and%20the%20goblet%20of%20fire
    Then I should see the text 'Works:'