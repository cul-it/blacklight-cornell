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
    And I should see the label '<title>'

  Examples:
  | bibid | title |
  | 1003756 | Struktura filosofskogo znanii︠a︡ |
  | 1077314 | A constitution for the socialist commonwealth of Great Britain |
  | 10976407 | 100 poems |
  | 120634 | Annulus wall boundary layers in turbomachines |
  | 2073985 | Cornell University Graduate School student records |
  | 277880 | An historical and critical account of the life and writing of the ever-memorable Mr. John Hales ... |
  | 285282 | Human rights quarterly |
  | 361984 | The annual of the British school at Athens |
  | 38097 | Encyclopedia of railroading |
  | 499380 | Ocean thermal energy conversion |
  | 595322 | Aesthetic experience and literary hermeneutics |
  | 67466 | Indian Ocean and regional security |
  | 721607 | World population |
  | 7596729 | Birds I have kept in years gone by |
  | 8623 | Dokumente zur Deutschlandpolitik |
  | 631947 | Growing against ourselves: the energy-environment tangle |
  | 6417953 | Abbott's encyclopedia of rope tricks for magicians |
  | 8816169 | Greek papyri from Montserrat (P.Monts.Roca IV) |
  | 6632477 | Purple rain |
  | 6395180 | 100% beef |
  | 130786 | Manual of the trees of North America (exclusive of Mexico) |
  | 3709643 | Mawsūʻat al-ʻimārah wa-funūn al-Islāmīyah |
  | 3749 | Convexity and duality in optimization |
  | 6701 | Birds of the Bahamas |
  | 301363 | Biology |
  | 115983 | The Economist |
  | 7142756 | 10 nam nhin lai |
  | 6926604 | Click |
  | 9668414 | Now that we're men |
  | 6829468 | 美国学者论美国中国学 / Meiguo xue zhe lun Meiguo Zhongguo xue |
  | 1001 | Reflections |
  | 12350238 | Cephalopod Culture |
  | 1378974 | Educating for world consciousness in the sixth grade |
  | 1002 | The principles and practice of diplomacy |
  | 6112378 | The Kalabagh Dam |
  | 13095898 | The insiders' guide to factual filmmaking |
  | 3261564 | Debabrata Biśvāsa |
  | 10055679 | Big chicken |
  | 10079768 | Zombies |
  | 10635622 | Sophisticated giant |
  | 247316 | The cheese and the worms |
  | 7981095 | Shelter medicine for veterinarians and staff |
  | 4481177 | AnthropologyPlus |
  | 5146902 | KMODDL |
  | 5458505 | Beautiful birds |
  | 6946453 | Black Studies Center |
  | 5861952 | Artefacts Canada |
  | 5346517 | ARTstor |
  | 8405575 | 转型、升级与创新 / Zhuan xing, sheng ji yu chuang xin |
  | 10297339 | China across the centuries |
  | 13283183 | The Boxer War |
  | 10294079 | Werke für Militärmusik und Panharmonikon |
  | 8297109 | Kammermusik mit Blasinstrumenten |
  | 10648489 | The most relaxing Beethoven album in the world-- ever! |
  | 7056812 | Do it anyway |
  | 6044052 | Perfect girls, starving daughters |
  | 1041597 | Sweet hands |
  | 996135 | Whipped cream & other delights |
