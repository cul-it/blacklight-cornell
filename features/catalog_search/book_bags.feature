@book_bags
@javascript
@omniauth_test
Feature: Book Bags for logged in users
    As a logged in user, I can store selected items in my book bag to refer to later on.

    @book_bags_sign_in
    Scenario: I can sign in to book bags
        Given we are in the development environment
        And I sign in to Book Bag
        Then I should see "You are logged in as Diligent Tester."

    @book_bags_select
    Scenario Outline: Items I select can be added to my book bag
        Given we are in the development environment
        And I sign in to BookBag
        When I go to the home page
        And I fill in the search box with 'rope work'
        And I press 'search'
        Then I should get results
        And there should be 0 items selected
        Then I select the first <count> catalog results
        When I go to BookBag
        And there should be <count> items selected

    Examples:
    | count |
    | 1 |
    | 2 |
    | 3 |
    | 4 |
    | 5 |


