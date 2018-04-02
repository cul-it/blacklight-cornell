@bookmarks
Feature: Bookmarks for anonymous users
    I want to be sure anonymous users can cite, export, and print selected items

    @javascript
    @bookmarks_exists
    @saml_on
    Scenario: Does the bookmarks page exist
#     Given PENDING javascript error
        When I literally go to bookmarks
        Then I should be on 'the bookmarks page'
        Then Sign in should link to Book Bags 
        And I should see a link "Selected Items"

    @javascript
    @saml_on
    @bookmarks_sign_in
    Scenario: If I try to sign in, I have to log in
        #Given PENDING Piwik javascript variable _paq is undefined
        When I go to the home page
        #Then show me the page
        And I expect Javascript _paq to be defined
        When I literally go to bookmarks
        And I expect Javascript _paq to be defined
        And click on link "Sign in"
        Then I should see the CUWebLogin page

    @javascript
    @bookmarks_select_items
    Scenario Outline: I can see the count of my selected items
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
    
    @javascript
    @saml_on
    @bookmarks_sign_in_links
    Scenario: I should log in via Book_bags from the Bookmarks page
        Given I am on the home page
        Then Sign in should link to the SAML login system
        When I literally go to search_history
        Then Sign in should link to the SAML login system
        When I literally go to advanced
        Then Sign in should link to the SAML login system
        When I literally go to bookmarks
        Then Sign in should link to Book Bags 

    @javascript
    @bookmarks_cite_selected
    Scenario: I should be able to view citations for selected items
        #Given PENDING when I get to /bookmarks I see 'You have no selected items.'
        Given I am on the home page
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results    
        Then I select the first 3 catalog results
        When I view my selected items
        Then I should be on 'the bookmarks page'
        And there should be 3 items selected
        Then I should see the text "Selected Items"
        And I should not see the text "You have no selected items."
        Then show me id "main-container"
        Then I should see the text "Cite"
        And I should not see the text "You have no selected items."
        # not sure what is wrong with view, and with ajax modal.
        #And I view my citations
        #And I sleep 6 seconds
        #Then in modal '#ajax-modal' I should see label 'APA 6th ed.'

 #    Given PENDING 
 #search for marvel masterworks, and get two results, select, and email them
 # cannot test this without login
  @bookmarks
  @javascript
  Scenario: Search with 2 results, select, and email them 
    Given I am on the home page
    When I fill in the search box with 'marvel masterworks'
    And I press "search"
    Then I should get results
    Then I should select checkbox "toggle_bookmark_8767648"
    Then click on link "Selected Items"
    And I should not see the text "You have no selected items."
    Then I should see the text "Marvel masterworks"

