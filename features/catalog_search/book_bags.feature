@book_bags
@javascript
@omniauth_test
Feature: Book Bags for logged in users
    As a logged in user, I can store selected items in my book bag to refer to later on.

    @book_bags_sign_in
    Scenario: I can sign in to book bags
        Given we are in any development or test environment
        And the test user is available
        And I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."

    @book_bags_navigation
    Scenario: The navigation area reminds me if I am logged in to Book Bags
        Given we are in any development or test environment
        And I go to the home page
        Then navigation should show 'Sign in'
        And navigation should show 'Selected Items'
        And navigation should not show 'Book Bag'
        Then I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."
        And I go to the home page
        Then navigation should show 'Sign out'
        And navigation should not show 'Selected Items'
        And navigation should show 'Book Bag'

    @book_bags_select
    Scenario Outline: Items I select can be added to my book bag
        Given we are in any development or test environment
        And I sign in to BookBag
        And I empty the BookBag
        Then the BookBag should be empty
        When I go to the home page
        And I fill in the search box with 'rope work'
        And I press 'search'
        Then I should get results
        And I select the first <count> catalog results
        Then navigation should show Book Bag contains <count>
        When I go to BookBag
        Then there should be <count> items in the BookBag

    Examples:
    | count | sleep |
    | 1 | 2 |
    | 2 | 2 |
    | 3 | 3 |
    | 4 | 3 |
    | 5 | 3 |
    | 10 | 5 |
    | 20 | 9 |

    @book_bags_bookmarks_redirect
    Scenario: Bookmarks redirect logged in users to Book Bags
        Given we are in any development or test environment
        And I sign in to BookBag
        Then navigation should show 'Book Bag'
        And I view my bookmarks
        Then I should see "Please use Book Bag while you are signed in."
        And navigation should show 'Book Bag'

    @book_bags_persisit
    Scenario: Items in the book bag should persist through logout
        Given we are in any development or test environment
        And I sign in to BookBag
        And I empty the BookBag
        Then the BookBag should be empty
        When I go to the home page
        And I fill in the search box with 'rope work'
        And I press 'search'
        Then I should get results
        And I should see 'Professional rope access : a guide to working safely at height'
        And I select the first 5 catalog results
        And I sleep 5 seconds
        When I go to BookBag
        Then there should be 5 items in the BookBag
        And I should see 'Professional rope access : a guide to working safely at height'
        Then I sign out
        And I go to the home page
        And I sign in to BookBag
        When I go to BookBag
        Then there should be 5 items in the BookBag
        And I should see 'Professional rope access : a guide to working safely at height'

    @book_bags_sign_in_anywhere
    Scenario Outline: I should be able to log in with the test user from any page
        Given we are in any development or test environment
        And the test user is available
        And I go to <page>
        And I sign in
        Then I should see "You are logged in as Diligent Tester."
        And navigation should show 'Book Bag'
        And I sign out

    Examples:
        | page |
        | the home page  |
        | the bookmarks page |
        | the detail page for id 11153474 |
        | the search history page |
        | the search everything page |


    @book_bags_cite_selected
    Scenario: I should be able to view citations for selected items
        Given we are in any development or test environment
        And the test user is available
        And I am on the home page
        And I sign in to BookBag
        And I empty the BookBag
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results
        Then I select the first 2 catalog results
        And I sleep 3 seconds
        When I go to BookBag
        And there should be 2 items in the BookBag
        Then I should see the text "Cite"
        And I clear transactions
        Then I disable ajax activity completion
        And I view my citations
        And I sleep 3 seconds
        Then the popup should include "APA 6th ed."
        And the popup should include "Chicago 17th ed."
        And the popup should include "MLA 7th ed."
        And the popup should include "MLA 8th ed."
        Then I close the popup
        And I sleep 1 second
        Then I enable ajax activity completion
        And I clear transactions

    @book_bags_export_selected
    Scenario: I should be able to export selected bookmarks
        Given we are in any development or test environment
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I clear transactions
        And I sleep 3 seconds
        Then navigation should show Book Bag contains 3
        When I go to BookBag
        And there should be 3 items in the BookBag
        Then click on link "Export"
        And the url of link "EndNote" should contain "endnote.endnote"
        And the url of link "RIS" should contain "endnote.ris"

    @book_bags_print_selected
    Scenario: I should be able to print selected items
        Given we are in any development or test environment
        And the test user is available
        And I am on the home page
        And I sign in to BookBag
        And I empty the BookBag
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 2 seconds
        When I view my selected items
        Then I should be on 'the bookmarks page'
        And there should be 3 items selected
        Then I should see the text "Selected Items"
        And I should not see the text "You have no selected items."
        And there should be a print bookmarks button

    @book_bags_save_bookmarks_to_book_bag
    Scenario: When I have Selected Items I should be able to add them to my Book Bag
        Given we are in any development or test environment
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
        And I sign out
        And I am on the home page
		When I fill in the search box with 'rope work'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 2 seconds
        When I view my selected items
        Then I should be on 'the bookmarks page'
        And there should be 3 items selected
        And click on link "Retrieve items from your Book Bag."
        Then I should be on 'BookBag'
        And the BookBag should be empty
        Then click on link "Sign in to enable your Book Bag"
        And I should see "You are logged in as Diligent Tester."
        And I should see "Add 3 Selected Items to your Book Bag"
        Then click on link "Add 3 Selected Items to your Book Bag"
        And there should be 3 items in the BookBag

    # @book_bags_clear_test
    # Scenario: I want to test
    #     Given I clear transactions





