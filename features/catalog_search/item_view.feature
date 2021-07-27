# encoding: UTF-8
Feature: Item view
  In order to get information about a specific item
  As a user
  I want to see details from the item's catalog record, holdings, and availability.
#  @all_item_view
#  @allow-rescue
#  @e404
#  Scenario: goto an invalid page

#    When I literally go to abcdefg
#    Then I should see an error
#    Then it should have link "mlink" with value "mailto:cul-dafeedback-l@cornell.edu"
  @all_item_view
  @availability
  Scenario: View an items holdings
    Given I request the item view for 4759
    Then I should see the label 'Request'
  @all_item_view
  @aeon
  @rmcnoitems
  Scenario: View an items holdings
    Given I request the item view for 8753977
    Then I should see the label 'Request'
  #@all_item_view
  #@aeon
  #  @reading_room_delivery
  #Scenario: View an items holdings, and request from aeon
  #  Given I request the item view for 2083253
  #      #And click on link "Request for Reading Room Delivery"
  #      Then it should have link "Request item for Reading Room Delivery" with value "http://voy-api.library.cornell.edu/aeon/monograph.php?bibid=2083253&libid=rmc,anx&finding="
  @all_item_view
  @aeon
  #Scenario: View an items holdings, and request from aeon
  #  Given I request the item view for 2083253
  #      And click on link "Request for Reading Room Delivery"
  #      Then I should see the label '16-5-268 This rare item may be delivered only to the RMC Reading Room.'
  @all_item_view
  @aeon
  #Scenario: View an items holdings, and request from aeon
  #  Given I request the item view for 2083253
  #      Then it should have link "Request for Reading Room Delivery" with value "/aeon/2083253"

  # DISCOVERYACCESS-136
  @all_item_view
  @DISCOVERYACCESS-136
  Scenario: As a user, the author's name in an item record is clickable and produces a query resulting in a list of works by that author.
    Given I request the item view for 6041
    And click on link "Catholic Church. Pope (1939-1958 : Pius XII)"
    Then results should have a "author" that looks sort of like "Catholic Church. Pope (1939"
    #Then results should contain "author" with value "Catholic Church. Pope (1939-1958 : Pius XII) Summi pontificatus (20 Oct. 1939) English."

  # DISCOVERYACCESS-137
  @all_item_view
  @DISCOVERYACCESS-137
  Scenario: As a user, the subject headings in an item record are clickable and produces a query resulting in a list of items.
    Given I request the item view for 1630516
    And I should see the label 'English poetry'
    And click on link "English poetry"
    Then it should contain filter "Subject" with value "English poetry"

  @all_item_view
  @DISCOVERYACCESS-137
  Scenario: As a user, the subject headings in an item record are clickable and are hierarchical.
    Given I request the item view for 1630516
    And click on link "19th century"
    Then it should contain filter "Subject" with value "English poetry > 19th century"

  # DISCOVERYACCESS-138
  @all_item_view
  Scenario: As a user, the "other names" in an item record is clickable and produces a query resulting in a list of items related to the other name chosen.
    Given I request the item view for 4442
    And click on link "Peabody, William Bourn Oliver, 1799-1847"
    Then I should see the label 'Lives of Alexander Wilson and Captain John Smith'

  # DISCOVERYACCESS-142
  @all_item_view
  Scenario: As a user I can see the publication date, publisher and place of publication on one line in the item record view.
    Given I request the item view for 3749
    Then it should contain "pub_info" with value "Berlin ; New York : Springer-Verlag, c1985."

  @aeon
  @all_item_view
  #Scenario: View an items holdings, and request from aeon
  #  Given I request the item view for 2083253
  #      And click on link "Request"
  #      Then I should see the label 'Upton, G. B. (George Burr), 1882-1942'

  #@aeon
  #@all_item_view
  #Scenario: View an items holdings, and request from aeon
  #  Given I request the item view for 2083253
  #      And click on first link "Request"
  #      Then I should see the label '16-5-268 This rare item may be delivered only to the RMC Reading Room.'

  @aeon
  @all_item_view
  #Scenario: View an items holdings, and request from aeon
  #  Given I request the item view for 2083253
  #      Then it should have link "Request" with value "/aeon/2083253"


  # DISCOVERYACCESS-136
  @DISCOVERYACCESS-136
  @all_item_view
  Scenario: As a user, the author's name in an item record is clickable and produces a query resulting in a list of works by that author.
    Given I request the item view for 6041
    And click on link "Catholic Church. Pope (1939-1958 : Pius XII)"
    Then results should have a "author" that looks sort of like "Catholic Church"

   # Then results should contain "author" with value "Catholic Church. Pope (1939-1958 : Pius XII) Summi pontificatus (20 Oct. 1939) English."

  # DISCOVERYACCESS-138
  @all_item_view
  Scenario: As a user, the "other names" in an item record is clickable and produces a query resulting in a list of items related to the other name chosen.
    Given I request the item view for 4442
    And click on link "Peabody, William Bourn Oliver, 1799-1847"
    Then I should see the label 'Lives of Alexander Wilson and Captain John Smith'

  # DISCOVERYACCESS-142
  @all_item_view
  Scenario: As a user I can see the publication date, publisher and place of publication on one line in the item record view.
    Given I request the item view for 3749
    Then it should contain "pub_info" with value "Berlin ; New York : Springer-Verlag, c1985."

  # Hiding request buttons for Folio migration so need to comment these two out.
  # @request_button
  # @all_item_view
  # @saml_off
  # Scenario: As a user I can request an item, when not SAML involved.
  #   Given I request the item view for 30000
  #   Then it should have link "Request item" with value "/request/30000"
  # 
  # @request_button
  # @all_item_view
  # @saml_on
  # Scenario: As a user I can request an item, when SAML involved.
  #   Given I request the item view for 30000
  #   Then it should have link "Request" with value "/request/auth/30000?scan=yes"

  # Availability simple, one location, and is available
  @availability
  @all_item_view
  Scenario: As a user I can see the availability for an item
    Given I request the item view for 30000
    Then I should see the label 'Library Annex'

  # The Kroch copy of this book has been checked out since July 1992.
  # https://newcatalog.library.cornell.edu/catalog/1208939
  # As a backup, I think this is a different patron who has had this book since October 1992:
  # https://newcatalog.library.cornell.edu/catalog/473013
  @all_item_view
  @availability @due
  Scenario: As a user I can see the availability for an item
    Given I request the item view for 1208939
    Then I should see the label 'Checked out, due'

  # availability -- several copies,all copy1, checked out.
  # Directory American Veterinary Medical Association
  # Temporarily commenting out while the Covid-19 changes are in place
  #@all_item_view
  #@availability
  #@javascript
  #@bibid1902405
  #@DISCOVERYACCESS-1659
  #@request
  #Scenario: As a user I can see the availability for an item
  #  Given I request the item view for 1902405
  #  #Then I should see the label '1950 c. 1 Checked out, due 2017-06-05'
  #  Then I should see the label 'Request'


  # when there is a perm location, and temp and all items for holding are at temp
  # then the temp location should be shown INSTEAD of permanent so "temporarily shelved
  # at" does not show , temporary shows as if it were permanent.
  # DISCOVERYACCESS-988
  @all_item_view
  @availability
  @DISCOVERYACCESS-988
  @request
  Scenario: As a user I can see the availability for an item at a temporary location that overrides the permanent location.
    Given I request the item view for 44112
    Then I should not see the label 'Temporarily shelved'

  @availability
  Scenario: As a user I can see the availability for an item on order
    Given I request the item view for 2696727
    Then I should see the label 'On Order'

  # display on order. DISCOVERYACCESS-1407
  @all_item_view
  @availability
  @DISCOVERYACCESS-1407
  Scenario: As a user I can see the availability for an item with an "open order" that does not say so.
    Given I request the item view for 2795276
    Then I should not see the label 'Copy Ordered'

  # Show that requests exist for an item.
  # DISCOVERYACCESS-1220
  # Item is overdue and should show that another request has been placed for it
  @all_item_view
  @availability
  @DISCOVERYACCESS-1220
  Scenario: As a user I can see the number of requests placed on an item
    Given I request the item view for 7943432
    Then I should see the label 'Request'

  # Make sure that blocking call number display does not cause availability display probs.
  # DISCOVERYACCESS-1386
  # items with no call number caused an exception -- so the text 'Call number' never
  # appears anyway, but we make sure we don't have an exception with null ptr.
  @all_item_view
  @availability
  @DISCOVERYACCESS-1386
  Scenario: As a user I can see the information about an ONLINE item, but not the call number
    Given I request the item view for 5380314
    Then I should see the label 'Online'

  #see holdings in Classic Catalog, but the space is just blank under “Availability” for this title in New Catalog.
  @availability
  @all_item_view
  @DISCOVERYACCESS-1558
  Scenario: As a user I can see the information about an  item when info in solr is slightly out of date
    Given I request the item view for 8688843
    Then I should see the label 'HD58.7 .S633 2014'

  # Availability for a lost item, and one available.
  @availability
  @all_item_view
  Scenario: As a user I can see the availability for an lost item (status 15) (Polymer Chemistry)
    Given I request the item view for 2144728
  #  Then I should see the labels 'Lost--System Applied 10/07/13'

  # Availability for a Missing item Municipal innovations
  @all_item_view
  @missing
  @availability
  Scenario: As a user I can see the availability for a Missing item
    Given I request the item view for 306998
    Then I should see the labels 'Missing'

  # Availability for an In transit item Mac OS X Tiger in a nutshell (status 10)
  @all_item_view
  @availability @intransit
  @DISCOVERYACCESS-1483
  Scenario: As a user I can see the availability for an In transit item
    Given I request the item view for 5729532
    Then I should see the labels 'Missing'

  # Availability for an In transit item bonsai culture and care
  @all_item_view
  @availability @intransit
  Scenario: As a user I can see the availability for an In transit item
    Given I request the item view for 52325
    Then I should see the labels 'In transit'

  # Availability for an In transit item The goldfinch
  @all_item_view
  @availability @intransit
  Scenario: As a user I can see the availability for an In transit item, but no bogus LOC
    Given I request the item view for 8272732
    Then I should not see the label '%LOC'

  # Availability for an In transit item status 10 - Declaration of a heretic
  @all_item_view
  @availability @intransit
  Scenario: As a user I can see the availability for an In transit item, but no bogus LOC
    Given I request the item view for 106223
    Then I should not see the label '%LOC'



  # Availability for a lost item status 14
  @all_item_view
  @availability
  Scenario: As a user I can see the availability for an lost item (status 14)
    Given I request the item view for 5318858
    Then I should see the label 'v.2 Lost--System Applied 08/26/14'

  # Availability for a lost item status 13
  @all_item_view
  @availability
  Scenario: As a user I can see the availability for an lost item (status 13)
    Given I request the item view for 259600
    Then I should see the label 'Lost--Library Applied 06/16/13'

  # Make sure subfield z is displayed.
  @all_item_view
  @availability
  @holdings_field866_subfieldz
  Scenario: As a user I can see the subfield Z in the holdings display info
    Given I request the item view for 2229355
    Then I should see the label 'Cayuga <Film 1290>'

  # Make sure Indexes: are displayed
  @all_item_view
  @availability
  @holdings
  @indexes
  Scenario: As a user I can see the indexes information
    Given I request the item view for 298714
    Then I should see the label 'Indexes'

  # Make sure Supplements: are displayed
  @all_item_view
  @availability
  @holdings
  @supplements
  Scenario: As a user I can see the supplements information
    Given I request the item view for 307178
    Then I should see the label 'Supplements:'

  # Make sure Current Issues: are displayed
  @all_item_view
  @availability
  @holdings
  @current_issues
  Scenario: As a user I can see the current issues information
    Given I request the item view for 329763
    Then I should see the label 'Subscription cancelled after 2009'

  # Make sure PDA makes some sense  DISCOVERYACCESS-1356
  # Confusing availability labels for 8036458
  @all_item_view
  @availability
  @holdings
  @pda
  Scenario: As a user I can see that an item is available for acquisition
    Given I request the item view for 38036458
    Then I should not see the label 'Library Technical Services Review Shelves'

  # DISCOVERYACCESS-1430 -- be more explicit in saying what is available.
  # Annotated Hobbit -- two locations, 1 copy at each.
  @all_item_view
  @availability
  @holdings
  @DISCOVERYACCESS-1430
  @DISCOVERYACCESS-1483
  Scenario: As a user I can see exactly what copy is available
    Given I request the item view for 1535861
    Then I should see the label 'Available c. 5'

  # DISCOVERYACCESS-1409 -- this record returns we are sorry
  # thai language material
  @all_item_view
  @DISCOVERYACCESS-1409
  Scenario: As a user I can see exactly what copy is available for this Thai language material
    Given I request the item view for 8258651
    Then I should not see the label '1 copy'
    Then I should see the label 'Available'

  # DISCOVERYACCESS-1430 -- be more explicit in saying what is available.
  # Fundamentals of corporate finance Stephen A. Ross, Randolph W. Westerfield, Bradford D. Jordan
  #@all_item_view
  #@availability
  #@holdings
  #@DISCOVERYACCESS-1430
  #@DISCOVERYACCESS-1483
  #Scenario: As a user I can see the how many copies are available
  #  Given I request the item view for 7728655
  #  Then I should see the label 'Available 1 copy'

  @uniformtitle
  @all_item_view
  Scenario: Item has both series title and uniform title (and they are clickable)
    Given I request the item view for 4759
    # DISCOVERYACCESS-148
    Then I should see the label 'Series'
    And click on link "Mangraithammasat"
    Then it should contain filter "Title" with value "Mangraithammasat"
    # DISCOVERYACCESS-149
    Given I request the item view for 4759
    Then I should see the label 'Uniform title'
    And click on link "Mangraithammasat"
    Then it should contain filter "Title" with value "Mangraithammasat"

  @all_item_view
  @linkfield
  Scenario: following linking fields
    Given I request the item view for 115093
    Then I should see the text 'Superseded by'

  # DISCOVERYACCESS-230
  #
  @linkfields
  @all_item_view

  Scenario Outline: Display Linking Title Display Fields
    Given I request the item view for <bibid>
    Then I should see the text <value>

  Examples:
    | bibid  | link | filter | value |
    # test continues_display
#    | 45766  | "International Printing and Graphic Communications Union. Convention. Convention proceedings of the International Printing & Graphic Communications Union" | "Title" | "Convention proceedings of the International Printing & Graphic Communications Union" |
    | 45766  | "International Printing and Graphic Communications Union. Convention. Convention proceedings of the International Printing & Graphic Communications Union" | "Title" | "Convention, Graphic Communications International Union" |
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
    | 115093 | "Nghiên cứu lịch sử." | "Title" | "Nghiên cứu lịch sử." |
     # test absorbed_by_display
    | 116073 | "National wildlife (DLC) 65066473 (OCoLC)1587904" | "Title" | "National wildlife" |
    # test absorbed_in_part_by_display
    | 118111 | "Alabama retail trade" | "Title" | "Alabama retail trade" |
    # test translation_of_display
    #| 115516 | "Kvantovai︠a︡ ėlectronika" | "Title" | "Kvantovai︠a︡ ėlectronika" |
    # test has_translation_display
    | 116482 | "Statistical yearbook of the Socialist Republic of Romania, 1966-" | "Title" | "Statistical yearbook of the Socialist Republic of Romania," |
    # test has_translation_display
    | 115317 | "Boletín de la Fundación Interamericana" | "Title" | "Boletín de la Fundación Interamericana" |
    # test supplement_display
    | 115621 | "Zeitschrift für Kunstgeschichte. Bibliographie des Jahres ... (DLC)sn 85004994 (OCoLC)7296517" | "Title" | "Zeitschrift für Kunstgeschichte. Bibliographie des Jahres ..." |
    # test other_form_display
    | 115113 | "United States. Bureau of Foreign and Domestic Commerce. Commerce reports July 1921-July 1925 (OCoLC)1533465" | "Title" | "Survey of current business (Online)" |
    # test issued_with_display
    | 115621 | "Online version: Zeitschrift für Kunstgeschichte (OCoLC)565894191" | "Title" | "Zeitschrift für Kunstgeschichte" |
    #| 301950 | "Lincoln law review v. 14, no. 1 (1983)" | "Title" | "Lincoln law review" |
    # test split_into_display
    | 264095 | "Together" | "Title" | "Together" |
    | 264095 | "New Christian advocate" | "Title" | "New Christian advocate" |
    # test merger_display
    | 115453 | "Chemical Society (Great Britain). Chemical Society reviews" | "Title" | "Chemical Society reviews" |
    | 115453 | "Chemical Society (Great Britain). Quarterly reviews" | "Title" | "Quarterly reviews" |


  @all_item_view
  Scenario Outline: Link to special content when available
    Given I request the item view for <bibid>
    Then I <yesno> see the label <label>

  Examples:
    | bibid | yesno      | label |
    # Test for links to full content and TOC
    #| 607   | should     | 'Available from the U.S. Government Printing Office. Adobe Acrobat Reader required' |
    | 608   | should not | 'Access online' |
    | 8212979 | should     | ' Table of contents' |
    | 608   | should not | 'Access table of contents' |
    # TODO: still need third case of content, as seen in 115628, but that record not available yet
    # DISCOVERYACCESS-?: Link to table of contents (or partial)
    | 4723  | should     | 'Table of contents' |
    | 4767  | should     | 'Partial table of contents' |
    | 4768  | should not | 'Table of Contents' |
    | 4768  | should not | 'Partial Table of Contents' |
    # DISCOVERYACCESS-?: Item description
    | 4626  | should     | 'Description' |
    | 5250067   | should not | 'Description' |

  @DISCOVERYACCESS-2968
  @all_item_view

  Scenario: Show the record notes field when available
    Given I request the item view for 4626
    Then it should contain "notes" with value "Notes:"
    Then it should contain "notes" with value "Includes indexes. Bibliography: p. 360-363."

    Given I request the item view for 4629
    Then I should not see the label 'Notes:'

 # not blow up when nothing returned by xisbn
 @DISCOVERYACCESS-1679
  @all_item_view
  Scenario: Show the record properly when xisbn does not work
    Given I request the item view for 8881455
    Then I should see the label 'Language'

 # various boundwith cases
  @all_item_view
 @boundwith
 @DISCOVERYACCESS-1903
 @DISCOVERYACCESS-1328
  Scenario: Show the record properly an item is bound with another item, and there are several volumes in separate items in other volumes
    Given I request the item view for 28297
    Then I should see the label 'This item is bound with'

#  @all_item_view
# @boundwith
# @DISCOVERYACCESS-1903
# @DISCOVERYACCESS-1328
#  Scenario: Show the record properly when it is bound with another item, but there is actually no item record for the bound with
#    Given I request the item view for 118111
#    Then I should see the label 'This item is bound with'

# I am not sure why I have to spell out the link completely here.
    #And it should have link "Calendar of the correspondence" with value "http://www.example.com/catalog/178799"
    #And it should have link "Supplement to Dr. W. A." with value "http://www.example.com/catalog/748299"
  @all_item_view
 @boundwith
 @DISCOVERYACCESS-1903
 @DISCOVERYACCESS-1328
  Scenario: Show the record properly when part of the item is bound with one other bibid, and one with another bibid
    Given I request the item view for 168319
    Then I should see the label 'Bound with'



 @all_item_view
 @boundwith
 @DISCOVERYACCESS-1903
 @DISCOVERYACCESS-1328
  Scenario: Show the record properly when it is bound with another item, one item is bound with another, one is not
    Given I request the item view for 211313
    Then I should see the label 'Bound with'

  @all_item_view
 @boundwith
 @DISCOVERYACCESS-1903
 @DISCOVERYACCESS-1328
  Scenario: Show the record properly when holding says bound with -- but it an electronic record.
    Given I request the item view for 6060112
    Then I should see the label 'Bound with'

  @all_item_view
 @boundwith
 @DISCOVERYACCESS-1903
 @DISCOVERYACCESS-1328
  Scenario: Show the record properly when holding has bound with multiple barcodes
    Given I request the item view for 3158956
    Then I should see the label 'Bound with'
    And it should have link "Revision of the genus Cinchona" with value "/catalog/3147365"
    And it should have link "Memoirs of the New York Botanical Garden" with value "/catalog/297559"

  @all_item_view
 @boundwith
 @DISCOVERYACCESS-2295
  Scenario: Show the record properly when a holding has no items
    Given I request the item view for 5972895
    Then I should see the label 'bound with'

  @popular
#  @all_item_view
#    Scenario: Show the record properly when a holding has only a prefix, but no callnumber as such.
#    Given I request the item view for 293396
#    Then I should see the label 'Popular Reading Area'

# this item is an online item, and has holding notes.
  @DISCOVERYACCESS-3325
  @online_holding_notes
  @all_item_view
    Scenario: Show the holding notes properly for online item.
    Given I request the item view for 8797135
    Then I should see the label '17th and 18th century Burney Collection'

  # TODO: need bibids that match these cases
# this item is an ordered item, received, and no item record.
# (I don't really know what ought to be displayed.)
#  @DISCOVERYACCESS-3243
#  @all_item_view
#    Scenario: Show the status properly for a received item, with no item record.
#    Given I request the item view for 9763600
#    Then I should see the label 'On-site use'
#    Then I should not see the label 'On order'


  # TODO: need bibids that match these cases

  # Scenario: Item has series title but not uniform title
  #   Given I request the item view for 4759
  #   Then I should see the label 'Series Title'
  #   And I should not see the label 'Uniform Title'

  # Scenario: Item has uniform title but not series title
  #   Given I request the item view for 4759
  #   Then I should not see the label 'Series Title'
  #   And I should see the label 'Uniform Title'

  # Scenario: Item has neither series nor uniform title
  #   Given I request the item view for 4759
  #   Then I should not see the label 'Series Title'
  #   And I should not see the label 'Uniform Title'
@all_item_view
@titlelinking
@DISCOVERYACCESS-1023
  Scenario: Show links to other formats when they exist
  Given I request the item view for 4163301
  Then I should see the text 'Other forms of this work'

# for  Scholastici orthodoxi specimen   --- an EEBO
@all_item_view
@tou
  Scenario: Show links to terms of use on electronic books
  Given I request the item view for 11493262
  #Then I should see the text 'Terms of use'
  Then I should see the text 'Scholastici orthodoxi specimen'

# Forró and redemptive regionalism from the Brazilian northeast
#@tou
#@all_item_view
#  Scenario: Show links to multiple terms of use on electronic books
#  Given I request the item view for 8445988
 # Then I should see the text 'Terms of use'
#  Then I should see the text '1 online resource'
#  And it should have link "Terms of use" with value "/catalog/tou/8445988/PRVAVX/C6C"
#  And it should have link "Terms of use" with value "/catalog/tou/8445988/PRVPQU/ATCPS"
#  And click on first link "Terms of use"
#  Then I should see the text 'Course Reserves by link only'


@insert_line_breaks
@all_item_view
  Scenario: Show table of contents with line breaks and not commas
  Given I request the item view for 9493653
  Then I should not see the text 'Volunteer's dilemma,'

#Kramer family papers
#1939-2009
  @all_item_view
  @finding_aid
  @DISCOVERYACCESS-2817
  Scenario: Show link to finding aid when present
    Given I request the item view for 2070362
    Then I should see the label 'Finding aid'
    And it should have link "Finding aid" with value "http://resolver.library.cornell.edu/cgi-bin/EADresolver?id=RMM03970"

#Attacking trigonometry problems
#David S. Kahn. with bookplate In memory of Albert Leskowitz.
  @all_item_view
  @bookplates
  @DISCOVERYACCESS-2823
  Scenario: Show link to e-bookplate
    Given I request the item view for 8948570
    Then I should see the label 'Bookplate'
    And it should have link "In memory of Albert Leskowitz." with value "http://plates.library.cornell.edu/donor/DNR00451"

#Confessio fidei exhibita invictiss
#The Eugene M. Kaufmann, Jr. Endowment Fund., The Arthur H. and Mary Marden Dean Book Fund.
  @all_item_view
  @bookplates
  @DISCOVERYACCESS-2823
  Scenario: Show link to e-bookplates
    Given I request the item view for 4473308
    Then I should see the label 'Bookplate'
    And it should have link "The Eugene M. Kaufmann, Jr. Endowment Fund." with value "http://plates.library.cornell.edu/donor/DNR00386"
    And it should have link "The Arthur H. and Mary Marden Dean Book Fund." with value "http://plates.library.cornell.edu/donor/DNR00373"



  @all_item_view
  @DISCOVERYACCESS-2881
  Scenario: Show multiple links to other online content
    Given I request the item view for 8913436
  #  Then I should see the label 'Online'
    Then I should see the label 'American Hospital Association annual survey database'
 #   And it should have link "Restricted access to authorized Cornell-affiliated users through CISER Data Archive (2012)" with value "http://www.ciser.cornell.edu/ASPs/search_athena.asp?IDTITLE=2765"
 #   And it should have link "Restricted access to authorized Cornell-affiliated users through CISER Data Archive (2013)" with value "http://www.ciser.cornell.edu/ASPs/search_athena.asp?IDTITLE=2766"

  # availability -- Spacecraft Planetary Imaging Facilty
  # Workshop on Martian Sulfates as Recorders of Atmospheric-Fluid Rock Interactions
  # bibid 9264410
  @hours-page
  @all_item_view
  @availability
  @javascript
  @bibid9264410
  @DISCOVERYACCESS-2855
  Scenario: As a user I can see the availability for an item
    Given I request the item view for 9264410
    # Temporary change for Covid-19: added 'not' to the following line.
    Then I should not see the label 'On-site use'
    And I should not see the label 'Request item'
    And it should have link "Hours/Map" with value "http://spif.astro.cornell.edu/"

  # availability -- Spacecraft Planetary Imaging Facilty , and also another library.
  # make sure we do NOT block request button just because SPIF.
  # Born a universe Hans Gennow
  # bibid 9203210
  @all_item_view
  @availability
  @javascript
  @bibid/9203210
  @DISCOVERYACCESS-3413
  Scenario: As a user I can see the availability for an item
    Given I request the item view for 9203210
    # Temporary change for Covid-19: added 'not' to the following line.
    Then I should not see the label 'On-site use'
    # Hiding request buttons for Folio migration so need to comment out this next line.
    # And I should see the label 'Request item'
    And it should have link "Hours/Map" with value "http://spif.astro.cornell.edu/"



  # The New York times
  # bibid 1545844
  @all_item_view
  @availability
  @javascript
  @bibid1545844
  @DISCOVERYACCESS-1380
  Scenario: As a user I can see the availability for an item
    Given I request the item view for 1545844
    Then I should see the label 'On-site use'
    # Commenting out for Folio migration
    #Then I should see the label 'Request item'

  @hours-page
  @on-site-use
  @all_item_view
  Scenario: View an items holdings, and have pointer to RMC help page.
    Given I request the item view for 2083253
    # Temporary change for Covid-19: added 'not' to the following line.
    Then I should not see the label 'On-site use'
    And it should have link "Hours/Map" with value "https://www.library.cornell.edu/libraries/rmc"

  @hours-page
  @on-site-use
  @all_item_view
  Scenario: View an hotel items holdings, and have pointer to ILR help page.
    Given I request the item view for 330333
    Then I should see the label 'On-site use'
    And it should have link "Hours/Map" with value "https://www.library.cornell.edu/libraries/rmc"

  # item view links to call number browse
#  @all_item_view
#  @item_view_call_number_browse_links
#  @DISCOVERYACCESS-4781
#  Scenario Outline: View an items holding, and get a link to Call Number Browse for each call number
#    Given I request the item view for <bibid>
#      And click on first link "<call_number>"
#      Then I should see the label 'Browse "<call_number>" in call numbers'
#      And I should see the text '<related_title>'

#  Examples:
#  | bibid | call_number | related_title |
#  | 366639 | ++ U1 .A744 | Army and navy journal. |
#  | 366639 | Film N6390 | United States army and navy journal. |
#  | 2557798 | PK2197.D43 T3 | T̤ālib Dihlavī, 1910- Yah thī Dillī. 1975. |
#  | 8338813 | LD1357.5 .C67 2014 | Cornell research. Office of the Vice Provost for Research, Cornell University, January 2014.  |
#  | 8338813 | Archives ARP 1164a | Cornell research. Office of the Vice Provost for Research, Cornell University, January 2014.  |
