@discogs
@javascript

Feature: Item view is enhanced with information from www.discogs.com

Scenario Outline: Recordings show Discogs information
    Given I request the item view for <asset_id>
    Then it should have title '<title>'
    And it should have a discogs disclaimer
    And I should see the text '<discogs_info>'

Examples:
    | asset_id | title | discogs_info |
    | 6632477 | Purple rain | Wendy Melvoin: Guitar, Voice. |
    | 996135 | Whipped cream & other delights | This Stereo Album may be played in Mono |

@DACCESS-675
Scenario Outline: Recordings do not show Discogs information
    Given I request the item view for <asset_id>
    Then it should have title '<title>'
    And it should not have a discogs disclaimer

Examples:
    | asset_id | title |
    | 16387366 | Music time USA |
    | 10573914 | The best of 2014 |