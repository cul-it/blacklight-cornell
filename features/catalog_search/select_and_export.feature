Feature: Select and export items from the result set

	In order to save results for later
	As a researcher
	I want to select items from a results list and export them in different ways.

	Background:

	Scenario: Select an item from the results list
		# Note: Checking the 'select' box on an item saves it to a personal Selected Items
		# set immediately via JavaScript

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
#Shannon, Timothy J. The Seven Years' War In North America : a Brief History with Documents. Boston: Bedford/St. Martin's, 2014.'
# has a 264 with indicator 1, and another with indicator 4.
@citations
@two264s
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8392067 
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'MLA Shannon, Timothy J. The Seven Years' War In North America : a Brief History with Documents. Boston: Bedford/St. Martin's, 2014.'

# roman numerals need to be properly eliminated from the date field.
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8125253
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'MLA Wake, William. Three Tracts Against Popery. Written In the Year Mdclxxxvi. By William Wake, M.a. Student of Christ Church, Oxon; Chaplain to the Right Honourable the Lord Preston, and Preacher At S. Ann's Church, Westminster. London: printed for Richard Chiswell, at the Rose and Crown in S. Paul's Church-Yard, 1687.'


# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8867518
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'MLA Fitch, G. Michael. The Impact of Hand-held and Hands-free Cell Phone Use On Driving Performance and Safety-critical Event Risk : Final Report. [Washington, DC]: U.S. Department of Transportation, National Highway Traffic Safety Administration, 2013.'

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8069112 
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'APA Cohen, A. I. (2013). Social media : legal risk and corporate policy. New York: Wolters Kluwer Law & Business.'

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8696757
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'Chicago Funk, Tom. Advanced Social Media Marketing: How to Lead, Launch, and Manage a Successful Social Media Program. Berkeley, CA: Apress, 2013.'

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
# test regular expression that expunges characters from date field.
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 5558811
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'MLA Eliot, John, John Cotton, and Robert Boyle. Mamusse Wunneetupanatamwe Up-biblum God Naneeswe Nukkone Testament Kah Wonk Wusku Testament. Cambridge [Mass.].: Printeuoop nashpe Samuel Green., 1685.'


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
  Scenario: Search with 2 results, select, and email them 
    Given I am on the home page
    When I fill in the search box with 'marvel masterworks'
    And I press "search"
    Then I should get results
    Then I should select checkbox "toggle_bookmark_8767648"
    Then I should select checkbox "toggle_bookmark_1947165"
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
    Then I should see "Location: Veterinary Library Core Resource (Non-Circulating)" in the email body
  
@DISCOVERYACCESS-1777
  Scenario: User sends a record by sms,which has no "status" -- no circulating copies Shelter medicine
    Given I request the item view for 7981095 
    And click on link "Text"
    And I fill in "to" with "6073516271"
    And I select 'Verizon' from the 'carrier' drop-down
    And I press "Send"
    And I sleep 2 seconds
    Then "6073516271@vtext.com" receives an email with "Shelter medicine for veterinarians and staff" in the content
    Then I should see "Shelter medicine for veterinarians and staff" in the email body
  

