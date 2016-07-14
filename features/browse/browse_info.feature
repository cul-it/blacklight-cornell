# encoding: UTF-8
Feature: Browse info  
  In order to get information about authorities 
  As a user
  I want to view specific author and subject authority records

  @browse
  Scenario: View an author authority record for a personal name
    Given I request the personal name author item view for Dickens,%20Charles,%201812-1870 
    Then I should see the text 'Works by:'

  @browse
  Scenario: View a subject authority record for a geographic name
    Given I request the geographic name subject item view for China%20%7C%20History 
    Then I should see the text 'Works about:'

  @browse
  Scenario: View an author title authority record for a work 
    Given I request the author title item view for Prince.%20%7C%20Purple%20rain 
    Then I should see the text 'Works:'