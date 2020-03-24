# encoding: UTF-8
Feature: Fail Quickly
  In order to free up the Jenkins testing queue
  As a programmer
  I want to make sure the first test that runs, fails

    # By default, Cucumber features/scenarios are run in the order:
    # Alphabetically by feature file directory
    # Alphabetically by feature file name
    # Order of scenarios within the feature file

  @fast_fail
  Scenario: Konk out right away
    # Given PENDING
    Then I should fail immediately
