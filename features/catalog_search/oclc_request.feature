Feature: Request Item by OCLC id. 

In order to request an item by oclcid 
As a user

# Vygotsky and Marx bibid bibid
# best way to test these is by running them
# where '/request' is NOT protected by CUWEBauth
# otherwise you get a JSON error parse during the login redirections.
# by default you should run cucumber with -t ~@oclc_request
@oclc_request
  Scenario: Request an item by oclc id when oclc id is valid 
    When I literally go to /oclc/970658422
    And I should see the text 'Pick up at'
    And I should see the text 'Vygotsky and Marx'

@oclc_request
  Scenario: Request an item by oclc id when oclc id is not valid 
    When I literally go to /oclc/97065842222222
    And I should not see the text 'Pick up at'
    And I should see the text 'Not Found'
