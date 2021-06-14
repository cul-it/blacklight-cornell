# encoding: UTF-8
@folio
Feature: Browse search
  In order to test FOLIO with a subset of catalog records
  As a user
  I want to be sure each bibid in the subset is available

  @DISCOVERYACCESS-7123
  Scenario Outline: View an available bibid
    Given I request the item view for <bibid>
    Then I should see the "doc_<bibid>" element

  Examples:
  | bibid |
  | 1003756 |
  | 1077314 |
  | 10976407 |
  | 120634 |
  | 2073985 |
  | 277880 |
  | 285282 |
  | 361984 |
  | 38097 |
  | 499380 |
  | 595322 |
  | 67466 |
  | 721607 |
  | 7596729 |
  | 8623 |
  | 631947 |
  | 5820954 |
  | 8816169 |
  | 6632477 |
  | 6395180 |
  | 130786 |
  | 3709643 |
  | 3749 |
  | 6701 |
  | 301363 |
  | 115983 |
  | 7142756 |
  | 6926604 |
  | 9668414 |
  | 6829468 |
  | 1001 |
  | 12350238 |
  | 1378974 |
  | 1002 |
  | 6112378 |
  | 13095898 |
  | 3261564 |
  | 10055679 |
  | 10079768 |
  | 10635622 |
  | 247316 |
  | 7981095 |
  | 4481177 |
  | 5146902 |
  | 5458505 |
  | 6946453 |
  | 5861952 |
  | 5346517 |
  | 8405575 |
  | 10297339 |
  | 13283183 |
  | 10294079 |
  | 8297109 |
  | 10648489 |
  | 7056812 |
  | 6044052 |
  | 1041597 |
  | 996135 |
