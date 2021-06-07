# encoding: UTF-8
Feature: Browse info
  In order to get information about authorities
  As a user
  I want to view specific author and subject authority records

  @browse
  Scenario: View an author authority record for a personal name
    Given I request the personal name author item view for Jauss,%20Hans%20Robert
    Then I should see the text 'Works by:'

  @browse
  Scenario: View a subject authority record for a geographic name
    Given I request the geographic name subject item view for Indian%20Ocean
    Then I should see the text 'Works about:'

  @browse
  Scenario: View an author title authority record for a work
    Given I request the author title item view for Dokumente%20zur%20Deutschlandpolitik
    Then I should see the text 'Works:'