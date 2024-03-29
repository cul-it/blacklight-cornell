# encoding: utf-8
@folio
@saml_off
Feature: Language Support
  In order to test FOLIO with a subset of catalog records
  As a developer
  I want to confirm requests are well supported

Scenario Outline: Request a scannable item
    Given I sign in to BookBag
    Then I should see "You are logged in as Diligent Tester."
    And I request the item view for <bibid>
    And I request the item
    Then I should see "Request Cornell library to library delivery"

Examples:
    | bibid | title |
    | 10055679 | Big chicken |
