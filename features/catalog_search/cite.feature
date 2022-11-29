@cite
@javascript
Feature: Citations for anonymous users
    I want to be sure anonymous users can cite items in various formats

    Scenario Outline: Scenario Outline name: As an anonymous user I can cite items in various formats
       Given I visit the Cite page for <asset_id>
       Then I should see the text "APA 6th ed."
       And I should see the text "Chicago 17th ed."
       And I should see the text "Council of Science Editors"
       And I should see the text "MLA 7th ed."
       And I should see the text "MLA 8th ed."
       And I should see the text "<citation>"

Examples:
    | asset_id | citation |
    | 9264410  | Workshop on Martian Sulfates as Recorders of Atmospheric-Fluid Rock Interactions. (2007).|
    | 28297 | Chapin, James Paul. |
    | 6701 | 1st ed. Kennebunkport, Me. |
    | 4073823 | Greene, W. T. (William Thomas). |
    | 5458505 | Rare and Manuscript Collections, 1999, |
