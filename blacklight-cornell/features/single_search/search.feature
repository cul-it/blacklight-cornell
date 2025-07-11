@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, and see results

  Scenario: Search Page
    When I go to the search page
    Then I should see a search field
    And I should see a "#search-btn" button
    And the page title should be "Cornell University Library Catalog"
    And I should see a stylesheet

  Scenario Outline: Specific challenging search strings should produce results
    When I go to the search page
    When I fill in "q" with '<search>'
    And I press 'Search'
    Then I should get bento results
    And I should see any text '<title>'

  Examples:
      | issue | search | title |
      | 6018 | Understanding HRM-firm performance linkages: the role of the "strength" of the hrm system  | Understanding HRM-firm performance linkages: the role of the "strength" of the hrm system |
      | 6019 | "HR system strength" bowen ostroff | REFLECTIONS ON THE 2014 DECADE AWARD: IS THERE STRENGTH IN THE CONSTRUCT OF HR SYSTEM STRENGTH? |
      | 6020 | system bowen firm performance linkage 2004 | Understanding HRM-firm performance linkages: the role of the "strength" of the hrm system |
      | 6021 | TOWARDS A THEORY OF MICRO-INSTITUTIONAL PROCESSES: FORGOTTEN ROOTS, LINKS TO SOCIAL-PSYCHOLOGICAL RESEARCH, AND NEW IDEAS. | TOWARDS A THEORY OF MICRO-INSTITUTIONAL PROCESSES: FORGOTTEN ROOTS, LINKS TO SOCIAL-PSYCHOLOGICAL RESEARCH, AND NEW IDEAS. |
      | 6022 | Institutional equivalence: how industry and community peers influence corporate philanthropy | Institutional equivalence: how industry and community peers influence corporate philanthropy |
      | 6023 | Superbugs versus Outsourced Cleaners: Employment Arrangements and the spread of health care-associated infections | Superbugs versus Outsourced Cleaners: Employment Arrangements and the spread of health care-associated infections |
      | 6024 | job level prior training sexual harassment | The impact of job level and prior training on sexual harassment labeling and remedy choice. |
      | 6025 | building sustainable hybrid organizations: the case of commercial microfinance organizations | building sustainable hybrid organizations: the case of commercial microfinance organizations |

  @DISCOVERYACCESS-6359
  Scenario Outline: When I search, the EDS results I should not see
    When I go to the search page
    When I fill in "q" with '<search>'
    And I press 'Search'
    Then the query "<search>" should show
    And I should get bento results
    And Articles & Full Text should not list "<search>"

  Examples:
      | search | comment |
      | Union Barley Coffee | not in the collection & not full text |
      # | Lion's Coffee | not in the collection & not full text |
      | McLaughlin's Coffee | not in the collection & not full text |
      | Coffee questionnaire | not in the collection & not full text |

  @DISCOVERYACCESS-6359
  Scenario Outline: When I search, the EDS results I should see
    When I go to the search page
    When I fill in "q" with '<search>'
    And I press 'Search'
    Then I should get bento results
    And Articles & Full Text should list "<search>"

  Examples:
      | search | comment |
      # PENDING | Hunting, Gathering, and Stone Age Cooking | |
      | Norton Anthology of World Religions: Islam | |
      | Concretions as sources of exceptional preservation | |
      | Utica Zoo, Utica Coffee Roasting | |

  @DISCOVERYACCESS-6699
  Scenario Outline: I can search for non-ascii strings
    When I go to the search page
    When I fill in "q" with '<search>'
    And I press 'Search'
    Then I should get bento results

  Examples:
      | search |
      | Basics of Legal Research”  |
      | If Only They’ Ask: Gender, Recruitment, and Political Ambition |
      | Hà Nội   |
      | 아, 김 수환 추기경 |

  @DIGCOLL-2228
  Scenario Outline: I can see Digital Collections search results in a Bento search
    When I go to the search page
    When I fill in "q" with '<search>'
    And I press 'Search'
    And I sleep 2 seconds
    Then Digital Collections should list '<result>'

  Examples:
      | search | result |
      | wooden nutmeg  | The blasphemy of abolitionism exposed  |
      | Hastingues | Council House with Three Filled Arches End Elevation |
      | Geryon | account of the pastoral life of the ancients |
      | 100% Beef | operations of the Cincinnati Branch |
      | crazy legs | Roxy, June 18, 1983 |
      | yard of pump water |  Principles and practice of plumbing |
      | purple | Color Applied to Dress Design |
      | Jazzbo | The Modern farmer |
