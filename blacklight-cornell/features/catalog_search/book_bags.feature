@book_bags
@javascript
@omniauth_test
Feature: Book Bags for logged in users
    As a logged in user, I can store selected items in my book bag to refer to later on.

    @book_bags_sign_in
    Scenario: I can sign in to book bags
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."

    @book_bags_navigation
    Scenario: The navigation area reminds me if I am logged in to Book Bags
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And I go to the home page
        And navigation should show 'Selected Items'
        And navigation should not show 'Book Bag'
        Then I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."
        And I go to the home page
        And navigation should not show 'Selected Items'
        And navigation should show 'Book Bag'

#    @book_bags_select
#    Scenario Outline: Items I select can be added to my book bag
#        Given we are in any development or test environment
#        And I sign in to BookBag
#        And I empty the BookBag
#        Then the BookBag should be empty
#        When I go to the home page
#        And I fill in the search box with 'the'
#        And I press 'search'
#        Then I should get results
#        And I select the first <count> catalog results
#        And I sleep <sleep> seconds
#        Then I clear the SQLite transactions
#        Then navigation should show Book Bag contains <count>
#        When I go to BookBag
#        Then there should be <count> items in the BookBag
#
#    Examples:
#    | count | sleep |
#    | 3 | 8 |
#    | 4 | 8 |
#    | 5 | 9 |
#    | 10 | 9 |
#    | 20 | 9 |

    @book_bags_bookmarks_redirect
    @javascript
    Scenario: Bookmarks redirect logged in users to Book Bags
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."
        And navigation should show 'Book Bag'
        And I view my bookmarks
        # I should be redirected back to /book_bags/index
        And I sleep 3 seconds
        Then navigation should show 'Book Bag'
        # Then I should see "Please use Book Bag while you are signed in." in the flash message

    @book_bags_persisit
    Scenario: Items in the book bag should persist through logout
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And I sign in to BookBag
        And I empty the BookBag
        Then the BookBag should be empty
        When I go to the home page
        And I fill in the search box with 'Britain'
        And I press 'search'
        And I sleep 2 seconds
        Then I should get results
        And I should see 'A constitution for the socialist commonwealth of Great Britain'
        And I select the first 3 catalog results
        And I sleep 5 seconds
        When I go to BookBag
        Then there should be 3 items in the BookBag
        And I should see 'A constitution for the socialist commonwealth of Great Britain'
        Then I sign out
        And I go to the home page
        And I sign in to BookBag
        When I go to BookBag
        Then there should be 3 items in the BookBag
        And I should see 'A constitution for the socialist commonwealth of Great Britain'

    @book_bags_sign_in_anywhere
    Scenario Outline: I should be able to log in with the test user from any page
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."
        Then I go to <page>
        And navigation should show 'Book Bag'
        And I sign out

    Examples:
        | page |
        | the home page  |
        # | the bookmarks page | - redirects to book bags
        # | the detail page for id 11153474 |
        | the search history page |
        | the search everything page |


    @book_bags_cite_selected
    Scenario Outline: I should be able to view citations for selected items
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I am on the home page
        And I sign in to BookBag
        And I empty the BookBag
		When I fill in the search box with '100 poems'
		And I press 'search'
		Then I should get results
        Then I select the first 1 catalog results
        And I sleep 2 seconds
        When I view my selected items
        Then I should be on 'BookBags'
        And there should be 1 item in the BookBag
        Then load 1 selected items
        And I should not see the text "You have no selected items."
        Then I should see the text "Cite"
        And I clear transactions
        Then I disable ajax activity completion
        And I view my citations in form "<format>"
        And I sleep 3 seconds
        Then the popup should include "<citation>"
        Then I close the popup
        And I sleep 1 second
        Then I enable ajax activity completion
        And I clear transactions

    Examples:
        | format | citation |
        | APA 6th ed. | Heaney, S. (2018). 100 poems. London: Faber & Faber. |
        | Chicago 17th ed. | Heaney, Seamus. 100 Poems. London: Faber & Faber, 2018. |
        | Council of Science Editors | Heaney S. 100 poems. London: Faber & Faber; 2018. |
        | MLA 7th ed. | Heaney, Seamus. 100 Poems. London: Faber & Faber, 2018. Print. |
        | MLA 8th ed. | Heaney, Seamus. 100 Poems. Faber & Faber, 2018. |


    @book_bags_export_selected
    Scenario: I should be able to export selected bookmarks
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
		When I fill in the search box with 'the'
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
        And I clear the SQLite transactions
        And the test user is available
        And I am on the home page
        And I sign in to BookBag
        And I empty the BookBag
		When I fill in the search box with 'the'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 2 seconds
        When I view my selected items
        Then I should be on 'BookBags'
        And there should be 3 items in the BookBag
        Then I should see the text "Book Bag"
        And I should not see the text "You have no selected items."
        And there should be a print bookmarks button

    @book_bags_save_bookmarks_to_book_bag
    Scenario: When I have Selected Items I should be able to add them to my Book Bag
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
        And I sign out
        And I clear the SQLite transactions
        And I am on the home page
		When I fill in the search box with 'the'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 3 seconds
        When I view my selected items
        Then I should be on 'the bookmarks page'
        And there should be 3 items selected
        And I sign in to BookBag
        When I go to BookBag
        Then I should be on 'BookBag'
        And the BookBag should be empty
        And I should see "Add 3 Selected Items to your Book Bag"
        Then I click and confirm "Add 3 Selected Items to your Book Bag"
        And there should be 3 items in the BookBag

    @DISCOVERYACCESS-6653
    @book_bags_initial_count
    Scenario: The correct Book Bags count should display in navigation area before going to book bags
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
        And I sign out
        And I sign in to BookBag
        Then I go to the home page
        And navigation should show the BookBag with no item count
		When I fill in the search box with 'the'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 5 seconds
        And I am on the home page
        And navigation should show 3 items in the BookBag

    @DISCOVERYACCESS-6653
    @book_bags_initial_count_quality
    Scenario: The correct Book Bags count should display after login from asset page
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
        Then I go to the home page
		When I fill in the search box with 'the'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 5 seconds
        Then navigation should show 3 items in the BookBag
        And I sleep 2 seconds
        And I sign out
        And I request the item view for 361984
        Then I should see the label 'The annual of the British school at Athens'
        And I sign in to BookBag
        And I sleep 2 seconds
        Then navigation should show the BookBag with no item count
        When I go to BookBag
        And there should be 3 items in the BookBag

    @DISCOVERYACCESS-7028
    Scenario: No stray percent sign in book bag count
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
        Then I go to the home page
		When I fill in the search box with 'of'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I clear transactions
        And I sleep 5 seconds
        Then navigation should show 3 items in the BookBag
        And navigation should not show '%'

    @DISCOVERYACCESS-8231
    Scenario: Article links from book bags lead to the article
        Given we are in any development or test environment
        And I clear the SQLite transactions
        And the test user is available
        And I sign in to BookBag
        And I empty the BookBag
        Then I go to the home page
        When I fill in the search box with 'encyclopedia of pain'
        And I press 'search'
        Then I should get results
        Then I select the first 1 catalog results
        And I clear transactions
        When I go to BookBag
        Then navigation should show 1 item in the BookBag
        And there should be 1 item in the BookBag
        Then I click on link "Encyclopedia of pain"
        Then I should see "9783540439578"
        Then I click on link "Back to Book Bag"
        And navigation should show 'Book Bag'

    # @book_bags_clear_test
    # Scenario: I want to test
    #     Given I clear transactions





