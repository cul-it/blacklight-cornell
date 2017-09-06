Feature: Request Item by OCLC id. 

In order to request an item by oclcid 
As a user

# Vygotsky and Marx bibid bibid
@all_search 
  Scenario: Request an item by oclc id when oclc id is valid 
    When I literally go to /oclc/970658422
    And I should see the text 'Pick up at'
    And I should see the text 'Vygotsky and Marx'

@all_search 
@allow_rescue
  Scenario: Request an item by oclc id when oclc id is not valid 
    When I literally go to /oclc/97065842222222
    And I should not see the text 'Pick up at'
    And I should see the text 'Not Found'
