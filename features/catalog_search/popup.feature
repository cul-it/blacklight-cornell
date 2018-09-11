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
    Given I request the item view for 7981095
    And click on link "Selected Items"
    And I sleep 5 seconds
    Then I should see the label 'You have no selected items'
    Given I request the item view for 7981095
    Then I should select checkbox "toggle_bookmark_7981095"
    And I sleep 5 seconds
    And click on link "Selected Items"
    Then I should see the label 'Shelter medicine for veterinarians and staff'

# there is a popup dialog, but poltergeist auto clicks okay,
#  Given PENDING
@all_select_and_export
@javascript
@popup
  Scenario: User select an item for list, and then clears list.
    Given I request the item view for 7981095
    And click on link "Selected Items"
    And I sleep 5 seconds
    Given I request the item view for 7981095
    Then I should select checkbox "toggle_bookmark_7981095"
    And I sleep 5 seconds
    And click on link "Selected Items"
    Then I should see the label 'Shelter medicine for veterinarians and staff'
    And I confirm popup "Clear all items"
    Then I should see the label 'You have no selected items'

  #Given PENDING
# there is a popup dialog, but poltergeist auto clicks okay,
@javascript
@popup
  Scenario: User select an item for list, and then clicks clear list but then cancels..
    Given I request the item view for 7981095
    And click on link "Selected Items"
    And I sleep 5 seconds
    Given I request the item view for 7981095
    Then I should select checkbox "toggle_bookmark_7981095"
    And I sleep 5 seconds
    And click on link "Selected Items"
    Then I should see the label 'Shelter medicine for veterinarians and staff'
    And I cancel popup "Clear all items"
    Then I should see the label '1 result'
