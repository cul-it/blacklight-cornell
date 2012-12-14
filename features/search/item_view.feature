Feature: Item view
  In order to get information about a specific item
  As a user
  I want to see details from the item's catalog record, holdings, and availability.

  Scenario: View an items holdings
  	Given I request the item holdings view for 4759
  	Then I should see the label 'Place request'

  # DISCOVERYACCESS-136
  Scenario: As a user, the author's name in an item record is clickable and produces a query resulting in a list of works by that author.
    Given I request the item view for 6041
    And click on link "Catholic Church. Pope (1939-1958 : Pius XII) English. Summi pontificatus (20 Oct. 1939)"
    Then it should contain "author" with value "Catholic Church. Pope (1939-1958 : Pius XII) English. Summi pontificatus (20 Oct. 1939)"

  # DISCOVERYACCESS-137
  Scenario: As a user, the subject headings in an item record are clickable and produces a query resulting in a list of items.
    Given I request the item view for 4696
    And click on link "English poetry"
    Then it should contain filter "Subject" with value "English poetry"
  Scenario: As a user, the subject headings in an item record are clickable and are hierarchical.
    Given I request the item view for 4696
    And click on link "19th century"
    Then it should contain filter "Subject" with value "English poetry 19th century"

  # DISCOVERYACCESS-138
  Scenario: As a user, the "other names" in an item record is clickable and produces a query resulting in a list of items related to the other name chosen.
    Given I request the item view for 4442
    And click on link "Peabody, William Bourn Oliver, 1799-1847"
    Then it should contain "title" with value "Lives of Alexander Wilson and Captain John Smith."

  # DISCOVERYACCESS-142
  Scenario: As a user I can see the publication date, publisher and place of publication on one line in the item record view.
    Given I request the item view for 3749
    Then it should contain "pub_info" with value "Berlin ; New York : Springer-Verlag, c1985."

  Scenario: Item has both series title and uniform title (and they are clickable)
  	Given I request the item view for 4759
  	# DISCOVERYACCESS-148
  	Then I should see the label 'Series Title'
    And click on link "Mangraithammasat"
    Then it should contain filter "Title" with value "Mangraithammasat"
  	# DISCOVERYACCESS-149
    Given I request the item view for 4759
  	Then I should see the label 'Uniform Title'
    And click on link "Mangraithammasat"
    Then it should contain filter "Title" with value "Mangraithammasat"

  # DISCOVERYACCESS-230
  Scenario Outline: Display Linking Title Display Fields
    Given I request the item view for <bibid>
    And click on link <link>
    Then it should contain filter <filter> with value <value>

  Examples:
    | bibid  | link | filter | value |
    # test continues_display
    | 45766  | "International Printing and Graphic Communications Union. Convention. Convention proceedings of the International Printing & Graphic Communications Union" | "Title" | "Convention proceedings of the International Printing & Graphic Communications Union" |
    # test continues_in_part_display
    | 115235 | "Journal of the Institute of Mathematics and its Applications" | "Title" | "Journal of the Institute of Mathematics and its Applications" |
    # test supersedes_display
    | 115115 | "Defectoscopy" | "Title" | "Defectoscopy" |
    # test absorbed_display
    | 115208 | "Student expenses at postsecondary institutions," | "Title" | "Student expenses at postsecondary institutions," |
    # test absorbed_in_part_display
    | 115113 | "Business conditions digest (DLC) 72621004 (OCoLC)2452279" | "Title" | "Business conditions digest" |
    # test continued_by_display
    | 115208 | "College costs and financial aid handbook" | "Title" | "College costs and financial aid handbook" |
    # test continued_in_part_by_display
    | 116073 | "Canadian wildlife (CaOONL)963900013 (OCoLC)34029039" | "Title" | "Canadian wildlife" |
    # test superseded_by_display
    | 115093 | "Nghiên cứu lịch sử." | "Title" | "Nghiên cứu lịch sử." |
     # test absorbed_by_display
    | 116073 | "National wildlife (DLC) 65066473 (OCoLC)1587904" | "Title" | "National wildlife" |
    # test absorbed_in_part_by_display
    | 118111 | "Alabama retail trade" | "Title" | "Alabama retail trade" |
    # test translation_of_display
    #| 115516 | "Kvantovai︠a︡ ėlectronika" | "Title" | "Kvantovai︠a︡ ėlectronika" |
    # test has_translation_display
    | 116482 | "Statistical yearbook of the Socialist Republic of Romania, 1966-" | "Title" | "Statistical yearbook of the Socialist Republic of Romania," |
    # test has_translation_display
    | 115317 | "Boletín de la Fundación Interamericana" | "Title" | "Boletín de la Fundación Interamericana" |
    # test supplement_display
    | 115621 | "Zeitschrift für Kunstgeschichte. Bibliographie des Jahres ... (DLC)sn 85004994 (OCoLC)7296517" | "Title" | "Zeitschrift für Kunstgeschichte. Bibliographie des Jahres ..." |
    # test other_form_display
    | 115113 | "United States. Bureau of Foreign and Domestic Commerce. Commerce reports July 1921-July 1925 (OCoLC)1533465" | "Title" | "Commerce reports" |
    # test issued_with_display
    | 115621 | "Online version: Zeitschrift für Kunstgeschichte (OCoLC)565894191" | "Title" | "Zeitschrift für Kunstgeschichte" |
    | 301950 | "Lincoln law review v. 14, no. 1 (1983)" | "Title" | "Lincoln law review" |
    # test split_into_display
    | 264095 | "Together" | "Title" | "Together" |
    | 264095 | "New Christian advocate" | "Title" | "New Christian advocate" |
    # test merger_display
    | 115453 | "Chemical Society (Great Britain). Chemical Society reviews" | "Title" | "Chemical Society reviews" |
    | 115453 | "Chemical Society (Great Britain). Quarterly reviews" | "Title" | "Quarterly reviews" |


  Scenario Outline: Link to special content when available
    Given I request the item view for <bibid>
    Then I <yesno> see the label <label>

  Examples:
    | bibid | yesno      | label |
    # Test for links to full content and TOC
    | 607   | should     | 'Access online' |
    | 608   | should not | 'Access online' |
    | 24669 | should     | 'Access table of contents' |
    | 608   | should not | 'Access table of contents' |
    # TODO: still need third case of content, as seen in 115628, but that record not available yet
    # DISCOVERYACCESS-?: Link to table of contents (or partial)
    | 4723  | should     | 'Table of Contents' |
    | 4767  | should     | 'Partial Table of Contents' |
    | 4768  | should not | 'Table of Contents' |
    | 4768  | should not | 'Partial Table of Contents' |
    # DISCOVERYACCESS-?: Item description
    | 4626  | should     | 'Description' |
    | 4627  | should not | 'Description' |

  # DISCOVERYACCESS -?
  Scenario: Show the record notes field when available
    Given I request the item view for 4626
    Then it should contain "notes" with value "Includes indexes.Bibliography: p. 360-363."

    Given I request the item view for 4629
    Then I should not see the label 'Notes'

  # DISCOVERYACCESS-?




  # TODO: need bibids that match these cases

  # Scenario: Item has series title but not uniform title
  # 	Given I request the item view for 4759
  # 	Then I should see the label 'Series Title'
  # 	And I should not see the label 'Uniform Title'

  # Scenario: Item has uniform title but not series title
  # 	Given I request the item view for 4759
  # 	Then I should not see the label 'Series Title'
  # 	And I should see the label 'Uniform Title'

  # Scenario: Item has neither series nor uniform title
  # 	Given I request the item view for 4759
  # 	Then I should not see the label 'Series Title'
  # 	And I should not see the label 'Uniform Title'
