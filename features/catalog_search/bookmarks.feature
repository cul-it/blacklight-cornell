@bookmarks
@javascript
Feature: Bookmarks for anonymous users
    I want to be sure anonymous users can cite, export, and print selected items

    @bookmarks_exists
    #@saml_on
    Scenario: Does the bookmarks page exist
        When I literally go to bookmarks
        Then I should be on 'the bookmarks page'
        Then I should see a button "Sign in to email items or save them to Book Bag"
        And I should see a link "Selected Items"

    @bookmarks_sign_in
    Scenario: If I try to sign in from bookmarks, I have to log in via book bags
        When I literally go to bookmarks
        Then I should see a button "Sign in to email items or save them to Book Bag"

    @bookmarks_select_items
    Scenario Outline: I can see the count of my selected items
        Given I am on the home page
        When I fill in the search box with 'the'
        And I press 'search'
        Then I should get results
        And there should be 0 items selected
        Then I select the first <count> catalog results
        And I sleep 5 seconds
        Then there should be <count> items selected
        When I literally go to bookmarks
        Then I should be on 'the bookmarks page'
        And there should be <count> items selected

    Examples:
    | count |
    | 1 |
    | 2 |
    | 3 |
    | 4 |
    | 5 |

    @bookmarks_cite_selected
    Scenario Outline: I should be able to view citations for selected items
        Given I am on the home page
		When I fill in the search box with '100 poems'
		And I press 'search'
		Then I should get results
        Then I select the first 1 catalog results
        And I sleep 2 seconds
        When I view my selected items
        Then I should be on 'the bookmarks page'
        And there should be 1 items selected
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

    @bookmarks_export_selected
    Scenario: I should be able to export selected bookmarks
        Given I am on the home page
		When I fill in the search box with 'the'
		And I press 'search'
		Then I should get results
        Then I select the first 3 catalog results
        And I sleep 3 seconds
        When I view my selected items
        Then I should be on 'the bookmarks page'
        And there should be 3 items selected
        Then load 3 selected items
        Then I should see the text "Selected Items"
        And I should not see the text "You have no selected items."
        Then click on link "Export"
        And the url of link "EndNote" should contain "endnote.endnote"
        And the url of link "RIS" should contain "endnote.ris"
        And I clear transactions


    @bookmarks_print_selected
    Scenario: I should be able to print selected items
        Given I am on the home page
		When I fill in the search box with 'the'
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


