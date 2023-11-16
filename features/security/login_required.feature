Feature: Login in is required before access to certain pages

Scenario Outline: Check pages that should require login

Given I am on <path_to>
	And I click on link <login_required>
	Then I should see the CUWebLogin page

Examples:
| path_to | login_required |
| the home page | Sign in |
