Feature: HTML Injection Tests

@DISCOVERYACCESS-7882
@javascript
Scenario Outline: As a hacker, I am prevented from showing some html on a library catalog page
When I literally go to <hack>
    And I should not see '<output>'
    And I press 'advanced_search'
    Then I should get results

Examples:
| hack | output |
| /edit?q_row[]=test%3E%3Cb%3Ethis-is-html%3C/b%3E | this-is-html |
| /edit?q_row%5b%5d=test%3E%3Cb%3EINJECT-ME%3C/b%3E | INJECT-ME |
| /edit?boolean_row[]=AND&boolean_row[]=AND&op_row[]=AND&op_row[]=AND&op_row[]=AND&q_row[]=test%3E%3Cb%3EINJECT-ME%3C/b%3E&q_row[]=test%3E%3Cb%3EINJECT-ME%3C/b%3E&q_row[]=test%3E%3Cb%3EINJECT-ME%3C/b%3E&search_field_row[]=all_fields&search_field_row[]=all_fields&search_field_row[]=all_fields | INJECT-ME |

Scenario Outline: As a hacker, I can crash advanced search
When I literally go to <hack>
    And I should not see '<output>'
    And I press 'advanced_search'
    Then I should get results

Examples:
| hack | output |
| /edit?q_row[]=curly&q_row[]=moe&q_row[]=larry | shep |