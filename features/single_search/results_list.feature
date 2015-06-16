Feature: Results list

	In order to find items that I search for
	As a user
	I want to view a list of search results with various options.

	Background:
        @empty_search
	Scenario: Empty search

    Given I literally go to search
		And I press 'Search'

		# Tests copied from Blacklight gem code
		Then I should be on 'the single search results page'
		And I should get bento results


	@search_with_no_results
  Scenario: Search with no results
    Given I literally go to search
    When I fill in "q" with 'awfasdf acawfdfas'
    And I press 'Search'
    Then I should not get bento results

  @search_with_best_bets
 	Scenario: Search with best bets
    Given I literally go to search
    When I fill in "q" with 'nature'
    And I press 'Search'
    Then I should get bento results
    And I should see the text "Best Bet"
    And I should see the text "from Catalog"

  @search_with_multi_word_best_bets
  Scenario: Search with multi word best bets
    Given I literally go to search
    When I fill in "q" with 'biosis previews'
    And I press 'Search'
    Then I should get bento results
    And I should see the text "Best Bet"

  @search_with_vern_text
  Scenario: Search with vern text
    Given I literally go to search
    When I fill in "q" with 'mao tse tung untold'
    And I press 'Search'
    Then I should get bento results
    #And I should see the text "珍藏毛泽东 = Mao Tse-tung untold"
    And I should see the text " 珍藏毛泽东 / Zhen cang Mao Zedong"


  @search_with_no_best_bets
  Scenario: Search with no best bets
    Given I literally go to search
    When I fill in "q" with 'otitis media'
    And I press 'Search'
    Then I should get bento results
    And I should not see the text "Best Bet"

  @search_with_view_all_websites
  Scenario: Search with view all websites link
    Given I literally go to search
    When I fill in "q" with 'nature study at Cornell University'
    And I press 'Search'
    Then I should get bento results
    When I follow "link_top_web"
    And I should see the text "nature study at Cornell University"

  @search_with_view_all_websites_multi_word
  Scenario: Search with view all websites multi word link
    Given I literally go to search
    When I fill in "q" with 'levitated nanosphere'
    And I press 'Search'
    Then I should get bento results
    When I follow "link_top_web"
    And I should see the text "levitated nanosphere"

	#https://issues.library.cornell.edu/browse/DISCOVERYACCESS-1135
  @search_with_view_all_websites_multi_word_with_percent
  Scenario: Search with view all websites multi word link
    Given I literally go to search
    When I fill in "q" with '100% beef'
    And I press 'Search'
    Then I should get bento results
    When I follow "link_top_web"
    And I should see the text "National Beef Packing Co"

  @search_with_view_all_books
  Scenario: Search with view all books link
    Given I literally go to search
    When I fill in "q" with 'nature'
    And I press 'Search'
    When I follow "link_top_book"
    And I should see the text "Nature 2012"

  @search_with_view_all_webs_match_box
  Scenario: Search with view all webs link
    Given I literally go to search
    When I fill in "q" with 'gettysburg address'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_web" should match "4" th "Library Websites" in "web-count"

  @search_with_view_all_music_match_box
  Scenario: Search with view all music link
    Given I literally go to search
    When I fill in "q" with 'nature morte'
    And I press 'Search'
		# Then I should get bento results
		Then box "link_top_musical_recording" should match "0" th "from Catalog" in "page_entries"

  @search_with_view_all_manuscript_archive
  Scenario: Search with view all music link
    Given I literally go to search
    When I fill in "q" with 'george burr upton'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_manuscript_archive" should match "0" th "from Catalog" in "page_entries"

  @search_with_view_all_webs_match_box_with_percent
  Scenario: Search with view all webs link
    Given I literally go to search
    When I fill in "q" with '100% beef packing'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_web" should match "2" nd "Library Websites" in "web-count"

  @search_with_view_all_journals_match_box_with_percent
  Scenario: Search with view all journals link
    Given I literally go to search
    When I fill in "q" with '100% beef'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_journal_periodical" should match "0" th "from Catalog" in "page_entries"

  @search_with_view_all_books_match_box_with_percent
  Scenario: Search with view all books link
    Given I literally go to search
    When I fill in "q" with '100% beef'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_book" should match "2" nd "from Catalog" in "page_entries"

  @search_with_view_all_computer_file_match_box_with_ampersand
  Scenario: Search with view all journals link
    Given I literally go to search
    When I fill in "q" with '100 Vietnamese painters & sculptors'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_computer_file" should match "0" th "from Catalog" in "page_entries"

  @search_with_view_all_journals_match_box_ampersand
  Scenario: Search with view all journals link  with ampersand
    Given I literally go to search
    When I fill in "q" with 'u & lc'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_journal_periodical" should match "0" th "from Catalog" in "page_entries"


  @search_with_view_all_book_match_box_ampersand
  Scenario: Search with view all books link  with ampersand
    Given I literally go to search
    When I fill in "q" with 'america & nepal'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_book" should match "0" th "from Catalog" in "page_entries"

  @search_with_view_all_article_match_box
  Scenario: Search with view all article link should match bento box total
    Given I literally go to search
    When I fill in "q" with 'stress testing cardio horse insights'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_summon_bento" should match "0" th "from Articles & Full Text" in "summary"


  @search_with_view_all_article_match_box
  Scenario: Search with view all article link should match bento box total
    Given I literally go to search
    When I fill in "q" with 'photoplethysmography methodological studies arterial stiffness'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_summon_bento" should match "0" th "from Articles & Full Text" in "summary"

  @search_with_view_all_web_match_box_ampersand
  Scenario: Search with view all webs link  with ampersand
    Given I literally go to search
    When I fill in "q" with 'america & nepal & rice & nematode'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_web" should match "1" st "Library Websites" in "web-count"

  @search_with_view_all_top_book_match_box_ampersand_and_others
  Scenario: Search with view all books  (top) link  with ampersand and others
    Given I literally go to search
    When I fill in "q" with ' & the $; or, Gold debts & taxes'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_book" should match "0" th "from Catalog" in "page_entries"

  @search_facet_web_match_box_ampersand
  Scenario: Search and facet webs link with ampersand match
    Given I literally go to search
    When I fill in "q" with 'nepali & language'
    And I press 'Search'
    Then I should get bento results
		Then facet "facet_link_web" should match "4" rd "Library Websites" in "web-count"

  @search_with_view_all_website_match_box
  Scenario: Search with view all related websites should match bentox box total
    Given I literally go to search
    When I fill in "q" with 'natural hazard statistics'
    And I press 'Search'
    Then I should get bento results
		Then box "link_top_website" should match "0" th "from Catalog" in "page_entries"
