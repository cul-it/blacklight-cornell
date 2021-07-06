# encoding: utf-8
@folio
Feature: Language Support
  In order to test FOLIO with a subset of catalog records
  As a developer
  I want to confirm requests are well supported

Scenario Outline: Request a scannable item
    Given I request the item view for <bibid>
    And I request the item
    Then I should see "Request Cornell library to library delivery"

Examples:
    | bibid | title |
    | 1812406 | Geometry, topology, and physics |
