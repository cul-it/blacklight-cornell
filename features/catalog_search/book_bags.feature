@book_bags
@javascript
@omniauth_test
Feature: Book Bags for logged in users
    As a logged in user, I can store selected items in my book bag to refer to later on.

    @book_bags_sign_in
    Scenario: I can sign in to book bags
        Given we are in the development environment
        And I sign in to BookBag
        Then I should see "You are logged in as Diligent Tester."

    @book_bags_navigation
    Scenario: The navigation area reminds me if I am logged in to Book Bags
        Given we are in the development environment
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
        Given we are in the development environment
        And I sign in to BookBag
        And I empty the BookBag
        Then the BookBag should be empty
        When I go to the home page
        And I fill in the search box with 'rope work'
        And I press 'search'
        Then I should get results
        And I select the first <count> catalog results
        And I sleep <sleep> seconds
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


