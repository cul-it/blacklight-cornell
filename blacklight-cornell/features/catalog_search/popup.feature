Feature: Select and export items from the result set

	In order to save results for later
	As a researcher
	I want to select items from a results list and export them in different ways.

	Background:

	Scenario: Select an item from the results list add to result list and deal with popup.
		# Note: Checking the 'select' box on an item saves it to a personal Selected Items
		# set immediately via JavaScript
@all_select_and_export
@javascript
@popup
  Scenario: User select an item for list, and then see item in list.
    Given I request the item view for 595322
    And I view my selected items
    And I sleep 5 seconds
    Then I should be on 'the bookmarks page'
    Then I should see the label 'You have no selected items'
    Given I request the item view for 595322
    Then I should select checkbox "toggle-bookmark_595322"
    And I sleep 5 seconds
    And I view my selected items
    And I sleep 5 seconds
    Then I should be on 'the bookmarks page'
    Then I should see the label 'Aesthetic experience and literary hermeneutics'

# there is a popup dialog, but poltergeist auto clicks okay,
@all_select_and_export
@javascript
@popup
  Scenario: User select an item for list, and then clears list.
    Given I request the item view for 595322
    And I view my selected items
    And I sleep 5 seconds
    Then I should be on 'the bookmarks page'
    Given I request the item view for 595322
    Then I should select checkbox "toggle-bookmark_595322"
    And I sleep 5 seconds
    And I view my selected items
    And I sleep 5 seconds
    Then I should be on 'the bookmarks page'
    Then I should see the label 'Aesthetic experience and literary hermeneutics'
    And I click and confirm "Clear all items"
    Then I should see the label 'You have no selected items'

# there is a popup dialog, but poltergeist auto clicks okay,
@javascript
@popup
  Scenario: User select an item for list, and then clicks clear list but then cancels..
    Given I request the item view for 595322
    And I view my selected items
    And I sleep 5 seconds
    Then I should be on 'the bookmarks page'
    Given I request the item view for 595322
    Then I should select checkbox "toggle-bookmark_595322"
    And I sleep 5 seconds
    And I view my selected items
    And I sleep 5 seconds
    Then I should be on 'the bookmarks page'
    Then I should see the label 'Aesthetic experience and literary hermeneutics'
    And I click and cancel "Clear all items"
    Then I should see the label '1 result'
