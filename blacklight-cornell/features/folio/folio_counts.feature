# encoding: utf-8
@folio
Feature: Browse search
  In order to test FOLIO with a subset of catalog records
  As a developer
  I want to confirm bibid counts in the test set

  Scenario: Count total records available
    Given I am on the home page
    And I search for everything
    Then I should get 235 results

  @all_results_list
  Scenario Outline: Counts for various search strings
    Given I am on the home page
    When I fill in the search box with '<query>'
	And I press 'search'
    Then I should get <count> results

  Examples:
      | query | count |
      | the  | 196  |
      | butter | 0 |
      | bird | 5 |
      | ocean | 2 |