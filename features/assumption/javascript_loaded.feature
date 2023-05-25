# encoding: UTF-8
Feature: Javascript
  In order to run javascript
  As a user
  I want to be sure all the javascript code has loaded correctly with the page

@javascript
Scenario Outline: Page has loaded all javascript
    When I go to <page>
    Then all javascript has loaded

Examples:
    | page |
    | the home page  |
