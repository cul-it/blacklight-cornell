# encoding: utf-8
@folio
@javascript
Feature: Language Support
  In order to test FOLIO with a subset of catalog records
  As a developer
  I want to confirm Syndetics Unbound table of content information is present

Scenario Outline: Show Syndetics table of contents when catalog TOC is missing
    # this is only expected to work on http://newcatalog-folio-int.library.cornell.edu/
    Given I request the item view for <bibid>
    Then I should see the label '<chapter>'

Examples:
    | bibid | chapter |
    | 8948570 |  The Basic Trig Ratios |
    | 10635622 | The Saga of Society Red |
    | 8036458 | An Overview of Reading Instruction for Struggling Readers |
