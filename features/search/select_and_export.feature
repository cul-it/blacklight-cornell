Feature: Select and export items from the result set

	In order to save results for later
	As a researcher
	I want to select items from a results list and export them in different ways.

	Background:

	Scenario: Select an item from the results list
		# Note: Checking the 'select' box on an item saves it to a personal Selected Items
		# set immediately via JavaScript

# DISCOVERYACCESS-1633 -- email should contain proper location, and temporary location, if appropriate
@DISCOVERYACCESS-1633
  Scenario: User sends a record by email
    Given I request the item view for 8767648
    And click on link "Email"
    And I fill in "to" with "quentin@example.com"
    And I press "Send"
    #And I sleep 2 seconds
    Then "quentin@example.com" receives an email with "Marvel masterworks" in the content 
    Then I should see "Marvel masterworks" in the email body
    Then I should see "Lee, Stan" in the email body
    Then I should see "Temporary Location: v.1   Temporarily shelved in Uris Library Reserv" in the email body
    Then I should see "Status: available" in the email body

		
#search for marvel masterworks, and get two results, select, and email them
@javascript
@select_and_email
  Scenario: Search with results
    Given I am on the home page
    When I fill in the search box with 'marvel masterworks'
    And I press "search"
    Then I should get results
    Then I should select checkbox "toggle_list_8767648"
    Then I should select checkbox "toggle_list_1947165"
    Then click on link "Selected Items"
    And click on link "Email"
    And I fill in "to" with "squentin@example.com"
    And I press "Send"
    And I sleep 4 seconds
    Then "squentin@example.com" receives an email with "Marvel masterworks" in the content 
    Then I should see "Status: available" in the email body
    Then I should see "Coward" in the email body
    Then I should see "Temporary Location: v.1   Temporarily shelved in Uris Library Reserv" in the email body
    Then I should see "Location:  Music Library A/V (Non-Circulating)" in the email body

@DISCOVERYACCESS-1670
  Scenario: User sends a record by email,which has no "status" -- no circulating copies Shelter medicine
    Given I request the item view for 7981095 
    And click on link "Email"
    And I fill in "to" with "quentin@example.com"
    And I press "Send"
    And I sleep 2 seconds
    Then "quentin@example.com" receives an email with "Shelter medicine for veterinarians and staff" in the content
    Then I should see "Shelter medicine for veterinarians and staff" in the email body
    Then I should see "xLocation: Veterinary Library Core Resource (Non-Circulating)" in the email body
  

