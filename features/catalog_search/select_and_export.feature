# encoding: utf-8 
Feature: Select and export items from the result set

	In order to save results for later
	As a researcher
	I want to select items from a results list and export them in different ways.

	Background:

	Scenario: Select an item from the results list
		# Note: Checking the 'select' box on an item saves it to a personal Selected Items
		# set immediately via JavaScript


# roman numerals need to be properly eliminated from the date field.
@all_select_and_export
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8125253
    And click on link "Cite"
    And I sleep 8 seconds
    Then I should see the label 'MLA 7th ed. Wake, William. Three Tracts against Popery. Written in the Year MDCLXXXVI. By William Wake, M.A. Student of Christ Church, Oxon; Chaplain to the Right Honourable the Lord Preston, and Preacher at S. Ann's Church, Westminster. London: printed for Richard Chiswell, at the Rose and Crown in S. Paul's Church-Yard, 1687. Web.'



#Chicago 17th ed. format.
# Official documentation: http://www.chicagomanualofstyle.org/16/ch14/ch14_sec018.html
# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
@all_select_and_export
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8696757
    And click on link "Cite"
    And I sleep 8 seconds
    Then I should see the label 'Chicago 17th ed. Funk, Tom. Advanced Social Media Marketing: How to Lead, Launch, and Manage a Successful Social Media Program. Berkeley, CA: Apress, 2013. https://doi.org/10.1007/978-1-4302-4408-0'

#For a book with two authors, note that only the 
#first-listed name is inverted in the bibliography entry.
#Ward, Geoffrey C., and Ken Burns. The War: An Intimate History, 1941–1945. New York: Knopf, 2007.
#Then I should see the label 'Chicago 16th ed. Ward, Geoffrey C, and Ken Burns. The War: An Intimate History, 1941–1945. New York: A.A. Knopf, 2007.'
@all_select_and_export
@citations
@DISCOVERYACCESS-1677 
@javascript
  Scenario: User needs to cite a record  with multiple authors.
    Given I request the item view for 6146988 
    And click on link "Cite"
    And I sleep 8 seconds
    Then I should see the label 'Chicago 17th ed. Ward, Geoffrey C, and Ken Burns. The War: an Intimate History, 1941-1945. New York: A.A. Knopf, 2007.'


@all_select_and_export
@citations
@javascript
  Scenario: User needs to cite a record by a corporate author. # Geology report / corp author.
    Given I request the item view for 393971
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'Chicago 17th ed. Memorial University of Newfoundland. Geology Report. St. John'

@javascript
@all_select_and_export
@citations
@javascript
@DISCOVERYACCESS-3175
  Scenario: User needs to cite a record by a editors. #  Fashion game changers 
    Given I request the item view for 9448862 
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'Chicago 17th ed. Modemuseum Provincie Antwerpen. Fashion Game Changers: Reinventing the 20th-Century Silhouette. Edited by Karen van Godtsenhoven, Miren Arzalluz, and Kaat Debo. London: Bloomsbury Visual Arts, an imprint of Bloomsbury Publishing PLC, 2016.'

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
#Shannon, Timothy J. The Seven Years' War In North America : a Brief History with Documents. Boston: Bedford/St. Martin's, 2014.'
# has a 264 with indicator 1, and another with indicator 4.
@all_select_and_export
@citations
@two264s
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8392067 
    And click on link "Cite"
    Then in modal '#ajax-modal' I should see label 'MLA 7th ed. Shannon, Timothy J. The Seven Years' War in North America: a Brief History with Documents. Boston: Bedford/St. Martin's, 2014. Print.'

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
@all_select_and_export
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record 
    Given I request the item view for 8867518
    And click on link "Cite"
    And I sleep 6 seconds
    Then in modal '#ajax-modal' I should see label 'MLA 7th ed. Fitch, G. Michael. The Impact of Hand-Held and Hands-Free Cell Phone Use on Driving Performance and Safety-Critical Event Risk: Final Report. [Washington, DC]: U.S. Department of Transportation, National Highway Traffic Safety Administration, 2013. Web.'

@all_select_and_export
@citations
@javascript
  Scenario: User needs to cite a record by a corporate author in MLA style # Geology report / corp author.
    Given I request the item view for 393971
    And click on link "Cite"
    And I sleep 6 seconds
    Then I should see the label 'MLA 7th ed. Memorial University of Newfoundland. Geology Report. St. John'


#User needs to cite a record by a corporate author in MLA style # NRC  / corp author. make sure (U.S.) is gone.
@all_select_and_export
@citations
@javascript
  Scenario: User needs to cite a record by a corporate author in MLA style # NRC  / corp author.
    Given I request the item view for 3902220 
    And click on link "Cite"
    And I sleep 6 seconds
    Then I should see the label 'MLA 7th ed. National Research Council. Beyond Six Billion: Forecasting the World's Population. Washington, D.C.: National Academy Press, 2000.'

# MLA 8th edition
@all_select_and_export
@citations
@javascript
  Scenario: User needs to cite a record by a corporate author in MLA 8th,7th, and CSE
    Given I request the item view for 7292123 
    And click on link "Cite"
    And I sleep 6 seconds
    Then I should see the label 'MLA 8th ed. Jacobs, Alan. The Pleasures of Reading in an Age of Distraction. Oxford University Press, 2011.'
    Then I should see the label 'MLA 7th ed. Jacobs, Alan. The Pleasures of Reading in an Age of Distraction. New York: Oxford University Press, 2011. Print.'
    Then I should see the label 'Council of Science Editors Jacobs A. The pleasures of reading in an age of distraction. New York: Oxford University Press; 2011.'

#
# APA 6th ed.
# Not sure if this is official documentation:
# http://www.muhlenberg.edu/library/reshelp/apa_example.pdf
# Publication Manual of the American Psychological Association, 6th ed. Washington, DC:
# American Psychological Association, 2010.
# Uris Library Reference (Non-Circulating) BF76.7 .P83 2010
# examples:
# Shotton, M. A. (1989) Computer addition? A study of computer dependency. London, England: Taylor & Francis
# Gregory, G., & Parry, T. (2006). Designing brain-compatible learning (3rd ed.). Thousand Oaks, CA: Corwin. 
# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
@all_select_and_export
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record in APA style. 
    Given I request the item view for 8069112 
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'APA 6th ed. Cohen, A. I. (2013). Social media: legal risk and corporate policy. New York: Wolters Kluwer Law & Business.'

@all_select_and_export
@citations
@DISCOVERYACCESS-1677 @javascript
  Scenario: User needs to cite a record with multiple authors in APA style
    Given I request the item view for 6146988
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'APA 6th ed. Ward, G. C., & Burns, K. (2007). The war: an intimate history, 1941-1945.'

@all_select_and_export
@citations
@javascript
  Scenario: User needs to cite a record by a corporate author in APA style # Geology report / corp author.
    Given I request the item view for 393971
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'APA 6th ed. Memorial University of Newfoundland. Geology report. St. John'

# DISCOVERYACCESS-2816 - Manuscript records should use cite as field
# Because of citeas, all fields should be the same.
@all_select_and_export
@javascript
  Scenario: User needs to cite a manuscript record
    Given I request the item view for 2083900
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'MLA 8th ed. Ezra Cornell Papers, #1-1-1. Division of Rare and Manuscript Collections, Cornell University Library.'
    Then I should see the label 'MLA 7th ed. Ezra Cornell Papers, #1-1-1. Division of Rare and Manuscript Collections, Cornell University Library.'
    Then I should see the label 'Council of Science Editors Ezra Cornell papers, #1-1-1. Division of Rare and Manuscript Collections, Cornell University Library.'
    Then I should see the label 'Chicago 17th ed. Ezra Cornell Papers, #1-1-1. Division of Rare and Manuscript Collections, Cornell University Library.'
    Then I should see the label 'APA 6th ed. Ezra Cornell papers, #1-1-1. Division of Rare and Manuscript Collections, Cornell University Library.'

# DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
# test regular expression that expunges characters from date field.
@all_select_and_export
@citations
@DISCOVERYACCESS-1677 
@javascript
  Scenario: User needs to cite a record with extra info expunged from date field. 
    Given I request the item view for 5558811
    And click on link "Cite"
    And I sleep 2 seconds
    Then I should see the label 'Chicago 17th ed. Eliot, John, John Cotton, and Robert Boyle. Mamusse Wunneetupanatamwe Up-Biblum God Naneeswe Nukkone Testament Kah Wonk Wusku Testament. Cambridge [Mass.].: Printeuoop nashpe Samuel Green., 1685.'
    Then I should see the label 'MLA 7th ed. Eliot, John, John Cotton, and Robert Boyle. Mamusse Wunneetupanatamwe Up-Biblum God Naneeswe Nukkone Testament Kah Wonk Wusku Testament. Cambridge [Mass.].: Printeuoop nashpe Samuel Green., 1685. Web.'
    Then I should see the label 'APA 6th ed. Eliot, J., Cotton, J., & Boyle, R. (1685). Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament. Cambridge [Mass.].: Printeuoop nashpe Samuel Green.'

# item view called twice because the formats are not registered till the item view is called once.
#
#TY  - EBOOK
#TI  - Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament
#AU  - Company for Propagation of the Gospel in New England and the Parts Adjacent in America
#PY  - 1685
#PB  - Printeuoop nashpe Samuel Green.
#CY  - Cambridge [Mass.].
#LA  - Algonquian (Other)
#UR  - http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=http://opac.newsbank.com/select/evans/385
#M2 - http://newcatalog.library.cornell.edu/catalog/5558811
#N1 - http://newcatalog.library.cornell.edu/catalog/5558811
#N1  - The second edition of Eliot's Indian Bible, revised by Eliot and John Cotton. 
#N1  - A dedication to the Hon. Robert Boyle was printed on a single leaf and inserted into the presentation copies sent abroad. Cf. Pilling, J.C. Bibliography of the Algonquian languages. 
#N1  - Printed in two columns. 
#N1  - "VVusku Wuttestamentum Nul-Lordumun Jesus Christ nuppoquohwussuaeneumun. Cambridge, Printed for the Right Honourable Corporation in London, for the Propogation [sic] of the Gospel among the Indians in New-England 1680."--p. [857-1116], with separate title page. First issued separately in 1680 (Evans 279). 
#N1  - The Psalms of David, p. [1117-1216], with caption title: Wame ketoohomae uketoohomaongash David. The Psalms were evidently issued separately as well, probably in 1682. 
#N1  - Rules for Christian living, by John Eliot, in Algonquian, p. [1217-1218]. 
#ER  - 

@all_select_and_export
@citations
@ris
  Scenario: User needs to send an ebook record to ris format (might go to zotero) 
    Given I request the item view for 5558811
    Given I request the item view for 5558811.ris
    Then I should see the text 'TY - EBOOK'
    Then I should see the text 'AU - Company for Propagation of the Gospel in New England and the Parts Adjacent in America'
    Then I should see the text 'TI - Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament'
    Then I should see the text 'PY  - 1685'
    Then I should see the text 'PB  - Printeuoop nashpe Samuel Green.'
    Then I should see the text 'CY  - Cambridge [Mass.].'
    Then I should see the text 'LA  - Algonquian (Other)'
    Then I should see the text 'UR  - http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=http://opac.newsbank.com/select/evans/385'
    Then I should see the text 'M2 - http://newcatalog.library.cornell.edu/catalog/5558811'
    Then I should see the text 'ER  -'

#TY - BOOK TI - Reflections : the anthropological muse PY - 1985 PB - American Anthropological Association CY - Washington, D.C. LA - English M2 - http://newcatalog.library.cornell.edu/catalog/1001 N1 - http://newcatalog.library.cornell.edu/catalog/1001 KW - Anthropologists' writings, American. KW - Anthropology Poetry. KW - American poetry 20th century. KW - Anthropologists' writings, English. KW - English poetry 20th century. CN - Library Annex PS591.A58 R33 SN - 091316710X : ER -
@all_select_and_export
@citations
@ris
  Scenario: User needs to send a book record to ris format (might go to zotero) 
    Given I request the item view for 1001 
    Given I request the item view for 1001.ris
    Then I should see the text 'TY - BOOK'
    Then I should see the text 'TI - Reflections: the anthropological muse'
    Then I should see the text 'CY - Washington, D.C.' 
    Then I should see the text 'CN - Library Annex PS591.A58 R33'
    Then I should see the text 'SN - 091316710X' 
    Then I should see the text 'ER  -'

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
    Then I should see the text '%T Reflections  the anthropological muse'

@all_select_and_export
@citations
  Scenario: User needs to send a book record to endnote format, check for processing 264  (might go to zotero) 
    Given I request the item view for 9939352 
    Given I request the item view for 9939352.endnote
    Then I should see the text '%T Octopus'
    Then I should see the text '%A Gray, Afsaneh' 
    Then I should see the text '%@ 1786821931' 
    Then I should see the text '%@ 9781786821935' 
    Then I should see the text '%0 Book'
    Then I should see the text '%C London'
    Then I should see the text '%D 2017' 
    Then I should see the text '%I Oberon Books'

@all_select_and_export
@citations
  Scenario: User needs to send an ebook record to endnote format
    Given I request the item view for 9305118 
    Given I request the item view for 9305118.endnote
    Then I should see the text '%0 Electronic Book'
    Then I should see the text '%A Boyle, P. R'
    Then I should see the text '%C Ames, Iowa'
    Then I should see the text '%D 2005' 
    Then I should see the text '%E Rodhouse, Paul' 
    Then I should see the text '%I Blackwell Science' 
    Then I should see the text '%@ 0632060484 (hardback : alk. paper)' 
    Then I should see the text '%T Cephalopods  ecology and fisheries' 

@all_select_and_export
@citations
  Scenario: User needs to send an ebook record to endnote format
    Given I request the item view for 6788245 
    Given I request the item view for 6788245.endnote
    Then I should see the text '%0 Film or Broadcast'
    Then I should see the text '%C Burbank, CA'
    Then I should see the text '%D c2009'
    Then I should see the text '%E Radcliffe, Daniel' 
    Then I should see the text '%E Rowling, J. K'
    Then I should see the text '%I Warner Home Video'
    Then I should see the text '%@ 1419864173'
    Then I should see the text '%@ 9781419864179'
    Then I should see the text '%T Harry Potter and the half-blood prince'
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
    Then I should see the xml text '<dc:identifier>ISBN 091316710X : '
    Then I should see the xml text '<rdf:value>Library Annex  PS591.A58 R33</rdf:value>'

#<rdf:Seq>
#<rdf:li>
#<foaf:Person>
#<foaf:surname>Cakrabarttī</foaf:surname>
#<foaf:givenname>Utpalendu</foaf:givenname>'
@citations
@rdf_zotero
@all_select_and_export
  Scenario: User needs to send a book record to ris format (might go to zotero) 
    Given I request the item view for 3261564
    Given I request the item view for 3261564.rdf_zotero
    Then I should see the xml text '<z:itemType>audioRecording</z:itemType>'
    Then I should see the xml text '<dc:title>Debabrata Biśvāsa</dc:title>'
    Then I should see the xml path 'z','//z:composers','http://www.zotero.org/namespaces/export#','Cakrabarttī'

@all_select_and_export
  Scenario: User needs to see search results as an atom feed, marc_xml
  When I literally go to catalog.atom?q=cheese+worms&search_field=all_fields&content_format=marc_xml
    Then I should see the xml text '<title>The cheese and the worms</title>'
    Then I should see the xml text '<name>Cornell University Library Catalog</name>'

@all_select_and_export @DISCOVERYANDACCESS-3766  @DISCOVERYANDACCESS-3766_basic
  Scenario: User needs to see zombies as a JSON feed
  When I literally go to /catalog.json?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
    Then I should see the text 'Zombies : an anthropological investigation of the living dead'
    And I should see the text 'At the Library'
    And I should see the text 'Gainesville : University Press of Florida, [2017]'
    And I should see the text 'GR581 .C4313 2017'
    And I should see the text 'Olin Library'
    And I should see the text '(OCoLC)982651297'

@all_select_and_export @DISCOVERYANDACCESS-3603 @DISCOVERYANDACCESS-3603_acquired_dt_sort
  Scenario: User needs to be able to sort search results by acquired date
  To replace http://newbooks.mannlib.cornell.edu we need to be able to sort search results
  by the acquired date of items.
    Given PENDING 
  When I go to the catalog page
    And I fill in the search box with 'knots rope'
    And I press 'search'
    Then I should get results
    And the first search result should be 'Encyclopedia of knots and fancy rope work'
    And the 'sort' select list should have an option for 'date acquired'
    Then I select the sort option 'date acquired'
    And the first search result should be 'A knot is where you tie a piece of rope : Burmese writing in Iowa' 

@all_select_and_export @DISCOVERYANDACCESS-3603 @DISCOVERYANDACCESS-3603_acquired_dt_returned
  Scenario: User needs to see the date acquired in a JSON feed
  When I literally go to /catalog.json?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
    Then I should see the text 'Zombies : an anthropological investigation of the living dead'
    And I should see the text 'acquired_dt'
    And I should see the text '2017-10-23T00:00:00Z'

@all_select_and_export @DISCOVERYANDACCESS-3603  @DISCOVERYANDACCESS-3603_rss
  Scenario: User needs to see zombies as an rss feed
  When I literally go to /catalog.rss?advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
    Then I should see the xml text '<title>Zombies : an anthropological investigation of the living dead</title>'
    And I should see the text 'Gainesville : University Press of Florida, [2017]'
    And I should see the text 'GR581 .C4313 2017 -- Olin Library'

@all_select_and_export @DISCOVERYANDACCESS-3603  @DISCOVERYANDACCESS-3603_atom
  Scenario Outline: User needs to see zombies as an atom feed
  When I literally go to /catalog.atom?content_format=<Format>&advanced_query=yes&boolean_row[1]=AND&counter=1&op_row[]=AND&op_row[]=AND&q=author%2Fcreator+%3D+Charlier&q_row[]=Zombies&q_row[]=Charlier&search_field=advanced&search_field_row[]=title&search_field_row[]=author%2Fcreator&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&total=1
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

#Then I should see the label '<content type="application/x-research-info-systems">'
# Pending causes an error in jenkins
# DISCOVERYACCESS-1633 -- email should contain proper location, and temporary location, if appropriate
@all_select_and_export
@DISCOVERYACCESS-1633
@select_and_email
@javascript
  Scenario: User sends a record by email
    Given PENDING 
    Given I request the item view for 8767648
    And click on link "Email"
    And I fill in "to" with "quentin@example.com"
    And I sleep 2 seconds
    And I press "Send"
    And I sleep 2 seconds
    Then "quentin@example.com" receives an email with "Marvel masterworks" in the content 
    Then I should see "Marvel masterworks" in the email body
    Then I should see "Lee, Stan" in the email body
  #  Then I should see "Status: v.1   c. 1 Checked out, due 2017-09-29" in the email body

#    Given PENDING 
#search for marvel masterworks, and get two results, select, and email them
@all_select_and_export
@javascript
@select_and_email
  Scenario: Search with 2 results, select, and email them 
    Given PENDING 
    Given I am on the home page
    When I fill in the search box with 'marvel masterworks'
    And I press "search"
    Then I should get results
    Then I should select checkbox "toggle_bookmark_8767648"
    Then I should select checkbox "toggle_bookmark_1947165"
    Then click on link "Selected Items"
    And click on link "Email"
    And I fill in "to" with "squentin@example.com"
    And I press "Send"
    And I sleep 4 seconds
    Then "squentin@example.com" receives an email with "Marvel masterworks" in the content 
    Then I should see "Status: available" in the email body
    Then I should see "Coward" in the email body
    Then I should see "Location:  Music Library A/V (Non-Circulating)" in the email body

  
@all_select_and_export
@DISCOVERYACCESS-1670
@DISCOVERYACCESS-1777
@select_and_email
@javascript
@popup
  Scenario: User sends a record by sms,which has no "status" -- no circulating copies Shelter medicine
    Given I request the item view for 7981095 
    And click on first link "Text"
    And I sleep 15 seconds
    And I fill in "to" with "6073516271"
    And I select 'Verizon' from the 'carrier' drop-down
    And I press "Send"
    And I sleep 12 seconds
    Then "6073516271@vtext.com" receives an email with "Shelter medicine for veterinarians and staf" in the content
    Then I should see "Shelter medicine for veterinarians and staf" in the email body
    Then I should see "Veterinary Library Core Resource (Non-Circulating)" in the email body
    And I sleep 8 seconds
  
