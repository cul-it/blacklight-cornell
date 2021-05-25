# encoding: utf-8
Feature: Select and export items from the result set

	In order to save results for later
	As a researcher
	I want to select items from a results list and export them in different ways.

	Background:

	Scenario: Select an item from the results list
		# Note: Checking the 'select' box on an item saves it to a personal Selected Items
		# set immediately via JavaScript
@all_select_and_export
@citations
  Scenario: User needs to send a book record to endnote format (might go to zotero)
    Given I request the item view for 1001
    Given I request the item view for 1001.endnote
    Then I should see the text '%0 Book'
    Then I should see the text '%C Washington, D.C.'
    Then I should see the text '%D 1985'
    Then I should see the text '%E Prattis, J. I'
    Then I should see the text '%I American Anthropological Association'
    Then I should see the text '%@ 091316710X'
    Then I should see the text '%T Reflections'
    Then I should see the text '%K Anthropology Poetry.'
    Then I should see the text '%K American poetry 20th century.'
    Then I should see the text '%K Anthropologists' writings, English.'
    Then I should see the text '%K Anthropologists' writings, American.'


@all_select_and_export
@citations
  Scenario: User needs to send an ebook record to endnote format
    Given I request the item view for 12350238
    Given I request the item view for 12350238.endnote
    Then I should see the text '%0 Electronic Book'
    Then I should see the text '%E José Iglesias'
    Then I should see the text '%D 2014'
    Then I should see the text '%A Roger Villanueva'
    Then I should see the text '%@ 9789401786485 (online)'
    Then I should see the text '%T Cephalopod Culture'

###
###
##
# <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:z=\"http://www.zotero.org/namespaces/export#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:vcard=\"http://nwalsh.com/rdf/vCard#\" xmlns:foaf=\"http://xmlns.com/foaf/0.1/\" xmlns:bib=\"http://purl.org/net/biblio#\" xmlns:prism=\"http://prismstandard.org/namespaces/1.2/basic/\" xmlns:dcterms=\"http://purl.org/dc/terms/\">\n
# <bib:Book>\n
# <z:itemType>book</z:itemType>\n
# <dc:title>Reflections : the anthropological muse</dc:title>\n
# <bib:authors>\n
# <rdf:Seq>\n
# <rdf:li>\n
# <foaf:Person>\n
# <foaf:surname>Prattis
# </foaf:surname>\n
# <foaf:givenname>J. I
# </foaf:givenname>\n
# </foaf:Person>\n
# </rdf:li>\n
# </rdf:Seq>\n
# </bib:authors>\n
# <dc:publisher>\n
# <foaf:Organization>\n
# <vcard:adr>\n
# <vcard:Address>\n
# <vcard:locality>Washington, D.C.
# </vcard:locality>\n
# </vcard:Address>\n
# </vcard:adr>\n
# <foaf:name>American Anthropological Association
# </foaf:name>\n
# </foaf:Organization>\n
# </dc:publisher>\n
# <dc:date>1985
# </dc:date>\n
# <z:language>English
# </z:language>\n
# <dc:subject>Anthropologists' writings, American.   </dc:subject>\n
# <dc:subject>Anthropology Poetry.  # </dc:subject>\n
# <dc:subject>American poetry 20th century.
# </dc:subject>\n
# <dc:subject>Anthropologists' writings, English.   </dc:subject>\n
# <dc:subject>English poetry 20th century.   </dc:subject>\n
# <dc:identifier>ISBN 091316710X :  </dc:identifier>\n
# <dc:coverage>Library Annex  PS591.A58 R33  </dc:coverage>\n
# <dc:subject>\n
# <dcterms:LCC>\n
# <rdf:value>Library Annex  PS591.A58 R33  </rdf:value>\n
# </dcterms:LCC>\n
# </dc:subject>\n
# <dc:identifier>\n
#<dcterms:URI><rdf:value>http://newcatalog.library.cornell.edu/catalog/1001</rdf:value></dcterms:URI>
# </dc:identifier>\n
# </bib:Book>\n
# </rdf:RDF>
@citations
@rdf_zotero
@all_select_and_export
  Scenario: User needs to send a book record to ris format (might go to zotero)
    Given I request the item view for 1001
    Given I request the item view for 1001.rdf_zotero
    Then I should see the xml text '<z:itemType>book</z:itemType'
    Then I should see the xml text '<dc:title>Reflections: the anthropological muse</dc:title>'
    Then I should see the xml text '<dc:identifier>ISBN 091316710X'
    Then I should see the xml text '<rdf:value>Library Annex  PS591.A58 R33</rdf:value>'

@all_select_and_export
@DISCOVERYACCESS-5430

  Scenario Outline: User needs to see various items in a citation format, check special, like thesis type, and ISBN.
    Given I request the item view for <BibId>
    Given I request the item view for <BibId>.<Format>
    Then I should see the xml text <SpecialContent>
    Examples:

| BibId | Format | SpecialContent |
| 1378974 | endnote |  '%A Condie, Carol Joy' |
| 1378974 | ris | 'AU  - Condie, Carol Joy' |
| 1378974 | endnote_xml| '<author>Condie, Carol Joy</author>' |
| 1002 | endnote | '%Z http://newcatalog.library.cornell.edu/catalog/1002' |
| 1002 | ris | 'M2  - http://newcatalog.library.cornell.edu/catalog/1002' |
| 1002 | endnote_xml | '<notes>http://newcatalog.library.cornell.edu/catalog/1002' |
| 1002 | rdf_zotero | '<dc:description>http://newcatalog.library.cornell.edu/catalog/1002</dc:description>' |
| 6112378 | rss | '<title>The Kalabagh Dam</title>' |

@all_select_and_export
@DISCOVERYACCESS-5438
  Scenario: As a developer, I want a sanity check for basic rss feed function
    Given I literally go to /catalog.rss
    Then I should see the xml text '<title>Search Results | Cornell University Library Catalog</title>'

@all_select_and_export
  Scenario Outline: User needs to see various items in a citation format, check DOI, URL for ebook
    Given I request the item view for <BibId>
    Given I request the item view for <BibId>.<Format>
    Then I should see the xml text <DoiXmlContent>
    Then I should see the xml text <UrlXmlContent>
    Examples:

|BibId | Format | DoiXmlContent |  UrlXmlContent |
| 13095898 | ris | 'UR  - https://www.taylorfrancis.com/books/9781351251464'  |'M2  - http://newcatalog.library.cornell.edu/catalog/13095898' |
| 13095898 | endnote | '%U https://www.taylorfrancis.com/books/9781351251464' | '%Z http://newcatalog.library.cornell.edu/catalog/13095898' |
| 13095898 | endnote_xml | '<publisher>Routledge</publisher>' | '<language>English</language>' |

#UR  - https://www.taylorfrancis.com/books/9781351251464
#N1  - http://newcatalog.library.cornell.edu/catalog/13095898
#AU  - Stark, Tony
#M2  - http://newcatalog.library.cornell.edu/catalog/13095898


#
#<rdf:Seq>
#<rdf:li>
#<foaf:Person>
#<foaf:surname>Cakrabarttī</foaf:surname>
#<foaf:givenname>Utpalendu</foaf:givenname>'
@citations
@rdf_zotero
@all_select_and_export
  Scenario: User needs to send a book record to rdf zotero format (might go to zotero)
    Given I request the item view for 3261564
    Given I request the item view for 3261564.rdf_zotero
    Then I should see the xml text '<z:itemType>audioRecording</z:itemType>'
    Then I should see the xml text '<dc:title>Debabrata Biśvāsa</dc:title>'
    Then I should see the xml path 'z','//z:composers','http://www.zotero.org/namespaces/export#','Cakrabarttī'

# check actual xpath to LCC
# e.g. <dcterms:LCC>
# <rdf:value>Mann Library  SF98.A5 M35 2017</rdf:value>
# </dcterms:LCC>

@all_select_and_export
  Scenario: User needs to send a book record to rdf zotero format (might go to zotero)
    Given I request the item view for 10055679
    Given I request the item view for 10055679.rdf_zotero
    Then I should see the xml path 'dcterms','//dcterms:LCC','http://purl.org/dc/terms/','Mann Library  SF98.A5 M35 2017'


@all_select_and_export
  Scenario: User needs to see search results as an atom feed, marc_xml
  When I literally go to catalog.atom?q=cheese+worms&search_field=all_fields&content_format=marc_xml
    Then I should see the xml text '<title>The cheese and the worms</title>'
    Then I should see the xml text '<name>Cornell University Library Catalog</name>'

@all_select_and_export @DISCOVERYANDACCESS-3766  @DISCOVERYANDACCESS-3766_basic
  Scenario: User needs to see zombies as a JSON feed
  #When I literally go to /catalog.json?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
  When I literally go to /catalog.json?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
    Then I should see the text 'Zombies : an anthropological investigation of the living dead'
    And I should see the text 'At the Library'
    And I should see the text 'Gainesville : University Press of Florida, [2017]'
    And I should see the text 'GR581 .C4313 2017'
    And I should see the text 'Olin Library'
    And I should see the text '982651297'


@all_select_and_export @DISCOVERYANDACCESS-3603 @DISCOVERYANDACCESS-3603_acquired_dt_returned
  Scenario: User needs to see the date acquired in a JSON feed
 # When I literally go to /catalog.json?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Vervaeke&q_row[]=Zombies&q_row[]=Vervaeke&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
  When I literally go to /catalog.json?q_row[]=Sophisticated+giant&op_row[]=phrase&search_field_row[]=all_fields&boolean_row[1]=AND&q_row[]=&op_row[]=AND&search_field_row[]=all_fields&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&search_field=advanced&advanced_query=yes&commit=Search
    Then I should see the text 'Sophisticated giant'
    And I should see the text 'acquired_dt'
    And I should see the text '2019-02-08T00:00:00Z'
    And I should get a response with content-type "application/json; charset=utf-8"

@all_select_and_export @DISCOVERYANDACCESS-3603  @DISCOVERYANDACCESS-3603_rss
  Scenario: User needs to see zombies as an rss feed
  #When I literally go to /catalog.rss?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
  When I literally go to /catalog.rss?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
    Then I should see the xml text '<title>Zombies : an anthropological investigation of the living dead</title>'
    And I should see the text 'Gainesville : University Press of Florida, [2017]'
    And I should see the text 'GR581 .C4313 2017 -- Olin Library'
    And I should get a response with content-type "application/rss+xml; charset=utf-8"

@all_select_and_export @DISCOVERYANDACCESS-3603  @DISCOVERYANDACCESS-3603_atom
  Scenario Outline: User needs to see zombies as an atom feed
  #When I literally go to /catalog.atom?content_format=<Format>&advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
  When I literally go to /catalog.atom?content_format=<Format>&advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
    Then I should see the xml text '<title>Zombies</title>'
    And I should see the xml text '<XmlContent>'
    And I should see the text '<TextContent>'

    Examples:
    | Format | XmlContent | TextContent |
    | xml | <dc:title>Zombies</dc:title> | Book |
    | dc_xml | <dc:title>Zombies</dc:title> | Book |
    | oai_dc_xml | <dc:title>Zombies</dc:title> | Book |
    | ris | <content type="application/x-research-info-systems"> | VFkgIC0gQk9PSwpUSSAgLSBab21iaWVzOiBhbiBhbnRocm9wb2xvZ2ljYWwg |
    | mendeley | <content type="application/x-research-info-systems"> | VFkgIC0gQk9PSwpUSSAgLSBab21iaWVzOiBhbiBhbnRocm9wb2xvZ2ljYWwg |
    | zotero | <content type="application/x-research-info-systems"> | VFkgIC0gQk9PSwpUSSAgLSBab21iaWVzOiBhbiBhbnRocm9wb2xvZ2ljYWwg |
    | rdf_zotero | <dc:subject>Vodou Haiti. </dc:subject> | an anthropological investigation of the living dead |

@all_select_and_export @DISCOVERYANDACCESS-3603  @DISCOVERYANDACCESS-3603_dc_xml
  Scenario: User needs to see search results as an atom feed, dc xml
  When I literally go to catalog.atom?q=cheese+worms&search_field=all_fields&content_format=dc_xml
    Then I should see the xml text '<title>The cheese and the worms</title>'
    Then I should see the xml text '<name>Cornell University Library Catalog</name>'
    Then I should see the xml path 'atom','//atom:entry/atom:title','http://www.w3.org/2005/Atom','The cheese and the worms'
    Then I should see the xml path 'dc','//dc:title','http://purl.org/dc/elements/1.1/','The cheese and the worms'
#    http://www.w3.org/2005/Atom

@all_select_and_export
  Scenario: User needs to see search results as an atom feed, ris
  When I literally go to catalog.atom?q=cheese+worms&search_field=all_fields&content_format=ris
    Then I should see the xml text '<title>The cheese and the worms</title>'
    Then I should see the xml text '<name>Cornell University Library Catalog</name>'
    Then I should see the xml text '<content type="application/x-research-info-systems">'

@all_select_and_export
@DISCOVERYACCESS-1670
@DISCOVERYACCESS-1777
@select_and_email
@javascript
@popup
  Scenario: User sends a record by sms,which has no "status" -- no circulating copies Shelter medicine
    Given I request the item view for 7981095
    And I text the first available item
    And I sleep 15 seconds
    And I fill in "to" with "6072213597"
    And I select 'Verizon' from the 'carrier' drop-down
    And I press "Send"
    And I sleep 12 seconds
    #Then "6072213597@vtext.com" receives an email with "Shelter medicine for veterinarians and staff" in the content
    #Then I should see "Shelter medicine for veterinarian..." in the email body
    #Then I should see "Veterinary Library Core Resource (5 hour loan)" in the email body
    And I sleep 8 seconds

