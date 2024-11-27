# encoding: UTF-8
Feature: Assumptions
  In order to get code coverage information on the tests
  As a user
  I want to be sure the environment variables are set correctly

@assumption
Scenario Outline: Check the environment variables
  Given I am on the home page
  Then the '<variable>' environment variable should be set to '<value>'

Examples:
  | variable | value |
  | RAILS_ENV  | test  |
  | COVERAGE | on |

@assumption
Scenario: Check for testing user
  Given I am on the home page
  Then the test user is available

@assumption
Scenario: Rails environment matches RAILS_ENV
  Given I am on the home page
  Then the Rails environment should be 'test'