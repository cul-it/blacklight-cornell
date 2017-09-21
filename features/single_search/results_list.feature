Feature: Results list

	In order to find items that I search for
	As a user
	I want to view a list of search results with various options.

	Background:
  @all_results_list @empty_search
  Scenario: Empty search
    Given I literally go to search
    And I press 'Search'
    Given I literally go to search
    And I press 'Search'
    # Tests copied from Blacklight gem code
    Then I should be on 'the single search results page'
    And I should get bento results

  @all_results_list @search_with_no_results
  Scenario: Search with no results
    Given I literally go to search
    When I fill in "q" with 'awfasdf acawfdfas'
    And I press 'Search'
    Then I should not get bento results

  @all_results_list @search_with_best_bets
  Scenario: Search with best bets
    Given I literally go to search
    When I fill in "q" with 'nature'
    And I press 'Search'
    Then I should get bento results
    And I should see the text "Best Bet"
    And I should see the text "from Catalog"

  @all_results_list @search_with_multi_word_best_bets
  Scenario: Search with multi word best bets
    Given I literally go to search
    When I fill in "q" with 'biosis previews'
    And I press 'Search'
    Then I should get bento results
    And I should see the text "Best Bet"

  @all_results_list @search_with_vern_text
  Scenario: Search with vern text
    Given I literally go to search
    When I fill in "q" with 'mao tse tung untold'
    And I press 'Search'
    Then I should get bento results
    #And I should see the text "珍藏毛泽东 = Mao Tse-tung untold"
    And I should see the text " 珍藏毛泽东 / Zhen cang Mao Zedong"


  @all_results_list @search_with_no_best_bets
  Scenario: Search with no best bets
    Given I literally go to search
    When I fill in "q" with 'otitis media'
    And I press 'Search'
    Then I should get bento results
    And I should not see the text "Best Bet"



  @all_results_list @search_with_view_all_books
  Scenario: Search with view all books link
    Given I literally go to search
    When I fill in "q" with 'nature'
    And I press 'Search'
    When I follow "link_top_book"
    Given PENDING
    And I should see the text "Altering nature c2008"

		@all_results_list @search_with_view_all_digital_collections
	  Scenario: Search with view all books link
	    Given I literally go to search
	    When I fill in "q" with 'game design'
	    And I press 'Search'
	    Then I should get bento results
	    And I should see the text "Def Jam"

		@all_results_list @search_with_view_advanced_link
		Scenario: Search with view all books link
			Given I literally go to search
			When I fill in "q" with 'game design'
			And I press 'Search'
			Then I should get bento results
			And I should see the text "or use advanced search"

  @all_results_list @search_with_view_all_libguides
  Scenario: Search with view all books link
    Given PENDING
	    Given I literally go to search
	    When I fill in "q" with 'business writing'
	    And I press 'Search'
	    Then I should get bento results
	    And I should see the text "Research Guides"

  @all_results_list @search_with_view_all_music_match_box
  Scenario: Search with view all music link
    Given I literally go to search
    When I fill in "q" with 'nature morte'
    And I press 'Search'
    Given PENDING
		# Then I should get bento results
		Then box "link_top_musical_recording" should match "0" th "from Catalog" in "page_entries"

  @all_results_list @search_with_view_all_manuscript_archive
  Scenario: Search with view all music link
    Given I literally go to search
    When I fill in "q" with 'george burr upton'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_manuscript_archive" should match "0" th "from Catalog" in "page_entries"



  @all_results_list @search_with_view_all_journals_match_box_with_percent
  Scenario: Search with view all journals link
    Given I literally go to search
    #When I fill in "q" with '100 beef'
    When I fill in "q" with 'beef'
    And I press 'Search'
    Then I should get bento results
    Given PENDING
		Then box "link_top_journal_periodical" should match "0" th "from Catalog" in "page_entries"

  @all_results_list @search_with_view_all_books_match_box_with_percent
  Scenario: Search with view all books link
    Given I literally go to search
    #When I fill in "q" with '100% beef'
    When I fill in "q" with 'beef'
    And I press 'Search'
    Then I should get bento results
    Given PENDING
		Then box "link_top_book" should match "2" nd "from Catalog" in "page_entries"

  @all_results_list @search_with_view_all_computer_file_match_box_with_ampersand
  Scenario: Search with view all journals link
    Given PENDING
    Given I literally go to search
    When I fill in "q" with '100 Vietnamese painters & sculptors'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_computer_file" should match "0" th "from Catalog" in "page_entries"

  @all_results_list @search_with_view_all_journals_match_box_ampersand
  Scenario: Search with view all journals link  with ampersand
    Given PENDING
    Given I literally go to search
    When I fill in "q" with 'u & lc'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_journal_periodical" should match "0" th "from Catalog" in "page_entries"


  @all_results_list @search_with_view_all_book_match_box_ampersand
  Scenario: Search with view all books link  with ampersand
    Given PENDING
    Given I literally go to search
    When I fill in "q" with 'america & nepal'
    And I press 'Search'
    And I sleep 30 seconds
    Given I literally go to search
    When I fill in "q" with 'america & nepal'
    And I press 'Search'
    And I sleep 30 seconds
    Then I should get bento results
		Then box "link_top_book" should match "0" th "from Catalog" in "page_entries"

  @all_results_list @search_with_view_all_article_match_box
  Scenario: Search with view all article link should match bento box total
    Given I literally go to search
    When I fill in "q" with 'stress testing cardio horse insights'
    And I press 'Search'
    Given PENDING
    Then I should get bento results
    Then box "link_top_summon_bento" should match "0" th "from Articles & Full Text" in "summary"


  @all_results_list @search_with_view_all_article_match_box
  Scenario: Search with view all article link should match bento box total
    Given I literally go to search
    When I fill in "q" with 'photoplethysmography methodological studies arterial stiffness'
    Given PENDING
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_summon_bento" should match "0" th "from Articles & Full Text" in "summary"


  @all_results_list @search_with_view_all_top_book_match_box_ampersand_and_others
  Scenario: Search with view all books  (top) link  with ampersand and others
    Given PENDING
    Given I literally go to search
    #When I fill in "q" with ' & the $; or, Gold debts & taxes'
    When I fill in "q" with 'Gold debts'
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_book" should match "0" th "from Catalog" in "page_entries"


# Combinatorial Algorithms, Algorithmic Press
# there is duplicate code here to defeat the 'circular dependency' problem,
# which sometimes results in false failures.
@all_results_list
@javascript
  Scenario: Perform an search with an unquoted call number
    Given I literally go to search
    When I fill in "q" with 'QA76.6 .C85 1972'
    And I press 'search'
    And I sleep 8 seconds
    Given I literally go to search
    When I fill in "q" with 'QA76.6 .C85 1972'
    And I press 'search'
    And I sleep 8 seconds
    Then I should get bento results
    And I should see the text "Combinatorial algorithms"

# Combinatorial Algorithms, Algorithmic Press
# there is duplicate code here to defeat the 'circular dependency' problem,
# which sometimes results in false failures.
@all_results_list
@javascript
  Scenario: Perform an search with a quoted call number
    Given I literally go to search
    When I fill in "q" with quoted 'QA76.6 .C85 1972'
    And I press 'search'
    Given I literally go to search
    When I fill in "q" with quoted 'QA76.6 .C85 1972'
    And I press 'search'
    Then I should get bento results
    And I should see the text "Combinatorial algorithms"
