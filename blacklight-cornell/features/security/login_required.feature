Feature: Login in is required before access to certain pages

@javascript
Scenario: Check home page Sign in button that looks like a link
Given I am on the home page
	And I set login required
	And I press "Sign in"
	Then I should see the CUWebLogin page
	Then I clear login required

@javascript
Scenario: Check home page My Account
Given I am on the home page
	Then I set login required
	And I click on link "My Account"
	Then I click on link "Log in with your NetID or GuestID"
	Then I should see the CUWebLogin page
	Then I clear login required

@javascript
Scenario: Check bookmarks sign in to email link
Given I am on the bookmarks page
	Then I set login required
	Then I press "Sign in to email items or save them to Book Bag"
	Then I should see the CUWebLogin page
	Then I clear login required

@javascript
Scenario: Check navigating directly to my account
Given I set login required
	And I am on my account
	Then I should see the CUWebLogin page
	Then I clear login required
