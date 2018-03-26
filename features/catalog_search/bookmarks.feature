@bookmarks
Feature: Bookmarks for anonymous users
    I want to be sure anonymous users can cite, export, and print selected items

    @bookmarks_exists
    @javascript
    Scenario: Does the bookmarks page exist
        When I literally go to bookmarks
        Then I should be on the bookmarks page
        And I should see a link "Sign in"
        And I should see a link "Selected Items"

    @bookmarks_sign_in
    @javascript
    Scenario: If I try to sign in, I have to log in
        When I go to the home page
        Then show me the page
        And I expect Javascript _paq to be defined
        When I literally go to bookmarks
        And I expect Javascript _paq to be defined
        And click on link "Sign in"
        Then I should see the CUWebLogin page

    @bookmarks_select_items
    @javascript
    Scenario Outline: I can see the count of my selected items
        Given PENDING javascript error
        Given I am on the home page
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results    
        And there should be 0 items selected
        Then I select the first <count> catalog results
        When I literally go to bookmarks
        And there should be <count> items selected

    Examples:
    | count |
    | 1 |
    | 2 |
    | 3 |
    | 4 |
    | 5 |
    
    @bookmarks_sign_in_links
    @javascript
    Scenario: I should log in via Book_bags from the Bookmarks page
        Given PENDING javascript error
        Given I am on the home page
        Then Sign in should link to the SAML login system
        When I literally go to search_history
        Then Sign in should link to the SAML login system
        When I literally go to advanced
        Then Sign in should link to the SAML login system
        When I literally go to bookmarks
        Then Sign in should link to Book Bags 

    @bookmarks_cite_selected
    @javascript
    Scenario: I should be able to view citations for selected items
        Given PENDING Selected Items do not show up on the /bookmarks page
        Given I am on the home page
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results    
        Then I select the first 3 catalog results
        When I view my selected items
        Then I should be on the bookmarks page
        And there should be 3 items selected
        Then I should see the text "Selected Items"
        Then show me id "main-container"
        Then I should see the text "Cite"
        And I should not see the text "You have no selected items."
        And I view my citations
        And I sleep 6 seconds
        Then in modal '#ajax-modal' I should see label 'APA 6th ed.'


