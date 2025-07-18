Feature: Results list

	In order to find items that I search for
	As a user
	I want to view a list of search results with various options.

	Background:
 @all_results_list @empty_search
 Scenario: Empty search
   Given I literally go to search
   And I press 'Search'
   And I sleep 8 seconds
   Then I should be on 'the single search results page'
   And I should get bento results

#why are there any results at all? when I specified no search terms?

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
    And I should see the text "Zhen cang Mao Zedong"


	#  @all_results_list @search_with_no_best_bets
	#Scenario: Search with no best bets
	#Given I literally go to search
	#When I fill in "q" with 'otitis media'
	#And I press 'Search'
	#Then I should get bento results
	#And I should not see the text "Best Bet"



  @all_results_list @search_with_view_all_books
  Scenario: Search with view all books link
    Given I literally go to search
    When I fill in "q" with 'nature'
    And I press 'Search'
    When I follow "link_top_book"
    And I should see the text "the double helix"

   @all_results_list @search_with_view_all_digital_collections
	  Scenario: Search with view all books link
	    Given I literally go to search
	    When I fill in "q" with 'delights'
	    And I press 'Search'
	    Then I should get bento results
	    And I should see the text "Whipped cream"

  @all_results_list @search_with_view_advanced_link
  Scenario: Search with view all books link
	    Given I literally go to search
	    When I fill in "q" with 'delights'
	    And I press 'Search'
	    Then I should get bento results
	    And I should see the text "or use advanced search"

  @all_results_list @search_with_view_all_libguides
  Scenario: Search and find a course guide
	    Given I literally go to search
	    When I fill in "q" with 'chemical process design course guide'
	    And I press 'Search'
	    Then I should get bento results
	    And I should see the text "Course Guides"

  @all_results_list @search_with_view_all_libguides
  Scenario: Search with view all books link
	    Given I literally go to search
	    When I fill in "q" with 'Translations'
	    And I press 'Search'
	    Then I should get bento results
	    And I should see the text "Research Guides"

#  @all_results_list @search_with_view_all_music_match_box
#  Scenario: Search with view all music link
#    Given I literally go to search
#    When I fill in "q" with 'nature morte'
#    And I press 'Search'
#     Then I should get bento results
   # Then box "link_top_musical_recording" should match "0" th "from Catalog" in "page-entries"

  @all_results_list @search_with_view_all_manuscript_archive
  Scenario: Search with view all music link
    Given I literally go to search
    When I fill in "q" with 'george burr upton'
    And I press 'Search'
    Then I should get bento results
#		Then box "link_top_manuscript_archive" should match "0" th "from Catalog" in "page-entries"



  @all_results_list
  @search_with_view_all_journals_match_box_with_percent
  Scenario: Search with view all journals link
    Given I literally go to search
    When I fill in "q" with 'chicken and egg'
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_journal_periodical" should match "0" th "from Catalog" in "page-entries"

  @all_results_list
  @search_with_view_all_books_match_box_with_percent
  Scenario: Search with view all books link
    Given I literally go to search
    #When I fill in "q" with '100% beef'
    When I fill in "q" with 'beefsteak'
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_book" should match "0" th "from Catalog" in "page-entries"

  @all_results_list @search_with_view_all_computer_file_match_box_with_ampersand
  Scenario: Search with view all journals link
    Given I literally go to search
    When I fill in "q" with '100 Vietnamese painters & sculptors'
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_computer_file" should match "0" th "from Catalog" in "page-entries"

  @all_results_list @search_with_view_all_journals_match_box_ampersand
  Scenario: Search with view all journals link  with ampersand
    Given I literally go to search
    When I fill in "q" with 'u & lc'
    And I press 'Search'
    Then I should get bento results
 #   Then box "link_top_journal_periodical" should match "0" th "from Catalog" in "page-entries"


  @all_results_list @search_with_view_all_book_match_box_ampersand
  Scenario: Search with view all books link  with ampersand
    Given I literally go to search
    When I fill in "q" with 'america & nepal'
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_book" should match "0" th "from Catalog" in "page-entries"

  @all_results_list @search_with_view_all_top_book_match_box_ampersand_and_others
  Scenario: Search with view all books  (top) link  with ampersand and others
    Given I literally go to search
    #When I fill in "q" with ' & the $; or, Gold debts & taxes'
    When I fill in "q" with 'Gold debts'
    And I press 'Search'
    Then I should get bento results
    Then box "link_top_book" should match "0" th "from Catalog" in "page-entries"


# Combinatorial Algorithms, Algorithmic Press
# there is duplicate code here to defeat the 'circular dependency' problem,
# which sometimes results in false failures.
@all_results_list
  Scenario: Perform an search with an unquoted call number
    Given I literally go to search
    When I fill in "q" with 'QA76.6 .C85 1972'
    And I press 'search'
    Then I should get bento results
    And I should see the text "Combinatorial algorithms"

# Combinatorial Algorithms, Algorithmic Press
# there is duplicate code here to defeat the 'circular dependency' problem,
# which sometimes results in false failures.
@all_results_list
  Scenario: Perform an search with a quoted call number
    Given I literally go to search
    When I fill in "q" with quoted 'QA76.6 .C85 1972'
    And I press 'search'
    Then I should get bento results
    And I should see the text "Combinatorial algorithms"

# bento search result digital collections thumbnails
@all_results_list
  Scenario: Search results should contain thumbnails
    Given I literally go to search
    When I fill in "q" with 'New York Times'
    And I press 'search'
    Then I should get bento results

# Digital Collections Portal search
# @all_results_list @dcp_search
Scenario Outline: Search within Portal results for each collection
  Given I literally go to search
  When I fill in "q" with '<query>'
  And I press 'Search'
  And I sleep 2 seconds
  Then I should get Digital Collections results
  Then Digital Collections should list "<item>"

Examples:
  | query | item |
  | iceland highest trees | The highest trees in Iceland. Birch 29 feet high |
  | wooden nutmeg | blasphemy of abolitionism exposed |
  | work bench | Tompkins County Work Bench in Cellar |
  | penitentiary | Society for the Alleviation of the Miseries |

# Institutional Repository search
@all_results_list @ir_search
Scenario Outline: Search within institutional repository results for each IR
  Given I literally go to search
  When I fill in "q" with '<query>'
  And I press 'Search'
  Then I should get Institutional Repository results
  And when I view all Repositories Items
  And I sleep 2 seconds
  Then I should see the text "<repository>"

Examples:
  | query | repository |
  | eye tracking | eCommons |
  | labor unrest | eCommons |
  | torts | Scholarship@Cornell Law |
  | barley | Agricultural Experiment Station |
  | Jurisprudence of Enron | Scholarship@Cornell Law |
  | Lessons from Guangdong Province | Charles H. Dyson School of Applied Economics |
  | Frederic Neyrat questions | la philosophie d'Alain Badiou |

@DISCOVERYACCESS-8225
Scenario: Articles & Full Text View all link should not have proxy
  Given I literally go to search
  When I fill in "q" with 'coffee'
  And I press 'Search'
  Then I should get Articles & Full Text results
  And the Articles View All link url should contain 'u2yil2' but not 'proxy.library'
  And the Articles heading link url should contain 'u2yil2' but not 'proxy.library'
  And the Articles format link url should contain 'u2yil2' but not 'proxy.library'
