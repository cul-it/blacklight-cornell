# encoding: utf-8
@folio
Feature: Browse search
  In order to test FOLIO with a subset of catalog records
  As a user
  I want to be sure each bibid in the subset is available

  @DISCOVERYACCESS-7123
  Scenario Outline: View an available bibid
    Given I request the item view for <bibid>
    Then I should see the label '<title>'

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
  | 1378974 | Educating for world consciousness in the sixth grade |
  | 1002 | The principles and practice of diplomacy |
  | 6112378 | The Kalabagh Dam |
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
  | 106223 | Declaration of a heretic |
  | 11493262 | Scholastici orthodoxi specimen |
  | 115093 | Tập san nghiên cứu văn sử địa |
  | 115113 | Survey of current business |
  | 115115 | The Soviet journal of nondestructive testing |
  | 115208 | The College cost book |
  | 115235 | IMA journal of applied mathematics |
  | 115317 | Journal of the Inter-American Foundation |
  | 115453 | RIC reviews |
  | 115621 | Zeitschrift für Kunstgeschichte |
  | 116073 | International wildlife |
  | 116482 | Anuarul statistic al Republicii Socialiste România |
  | 118111 | Alabama business |
  | 1208939 | Chi Pheo and other stories |
  | 1535861 | The annotated Hobbit |
  | 1545844 | The New York times |
  | 1630516 | An Anthology of Chartist poetry |
  | 168319 | Actes du consistoire de l'Église française de Threadneedle street, Londres ... |
  | 2070362 | Kramer family papers |
  | 2083253 | George Burr Upton papers |
  | 211313 | Australien nach dem stande der geographischen kenntniss in 1871 |
  | 2144728 | Polymer chemistry |
  | 2229355 | Agricultural schedules of New York State by counties |
  | 259600 | Diversification through acquisition |
  | 264095 | Christian advocate |
  | 2696727 | Race, ethnicity and multiculturalism |
  | 2795276 | The Malott times |
  | 298714 | The Academy of Management review |
  | 30000 | Impact of budget proposals on income maintenance programs, trade and economic policy, state and local issues |
  | 306998 | Municipal innovations |
  | 307178 | Journal of equine veterinary science |
  | 3158956 | Systematics of Erisma (Vochysiaceae) |
  | 329763 | Nature |
  | 330333 | Ithaca times |
  | 4163301 | Harry Potter og eldbikarinn |
  | 8918300 | แฮรี่ พอตเตอร์กับถ้วยอัคนี / Hǣri Phō̜ttœ̄ kap thūai ʻakkhanī |
  | 5727137 | Hārī Pūtir wa-kaʼs al-nār |
  | 3856962 | Harry Potter and the goblet of fire |
  | 3855887 | Harry Potter und der Feuerkelch |
  | 7571753 | Hyāri Paṭāra ayāṇḍa dya gabaleṭa aba phāẏāra |
  | 3849306 | Harry Potter and the goblet of fire |
  | 9898648 | Harry Potter et la coupe de feu |
  | 44112 | This sex which is not one |
  | 4442 | Lives of Alexander Wilson and Captain John Smith |
  | 4473308 | Confessio fidei exhibita invictiss. imp. Carolo V. Caesari Aug. in comicijs Augustae. Anno MDXXX ; Addita est Apologia co[n]fessionis ; Psalm 119 ; Et loquebar de testimoniis tuis in conspectu Regum, & non consundebar |
  | 45766 | Proceedings of the ... Convention, Graphic Communications International Union |
  | 4626 | D.H. Lawrence |
  | 4629 | Das Selbstbestimmungsrecht der Völker und die Sowjetunion |
  | 4723 | Handbuch der Mineralogie |
  | 4759 | Mangrāisāt chabap Chīangman, tonchabap Wat Chīangman, ʻAmphœ̄ Mư̄ang, Čhangwat Chīang Mai |
  | 4767 | Introduction to the study of international law |
  | 4768 | Xây dựng và nhân điển hình |
  | 52325 | Bonsai |
  | 5250067 | A correct statement of the grand cricket-match, played at Worksop, on Monday, Tuesday, and Wednesday, the 3d, 4th, and 5th of November 1800, by eleven members of the Nottingham Club, against twenty-two members of the Sheffield Club, for two hundred guineas |
  | 5318858 | Sexual orientation and the law |
  | 5380314 | The New York times |
  | 5729532 | Mac OS X Tiger in a nutshell |
  | 5972895 | Chính sách tôn giáo của Đảng |
  | 6041 | Encyclical letter of Pope Pius XII, October 20, 1939 |
  | 6060112 | Household discoveries |
  | 608 | U.S. coal goes abroad |
  | 7943432 | The basic practice of statistics |
  | 8212979 | Ancient libraries |
  | 8258651 | อนุสรณ์งานพระราชทานเพลิงศพ ศาสตราจารย์ (พิเศษ) ดร. กำธร สถิรกุล ป.ม., ท.ช / ʻAnusō̜n ngān phrarātchathān phlœ̄ng sop Sātsatrāčhān (Phisēt) Dō̜rō̜. Kamthō̜n Sathirakun Pō̜. Mō̜., Thō̜. Chō̜ |
  | 8272732 | The goldfinch |
  | 8688843 | Beyond inclusion |
  | 8753977 | Kenneth A. R. Kennedy papers |
  | 8797135 | Gale |
  | 8913436 | AHA annual survey database |
  | 8948570 | Attacking trigonometry problems |
  | 9203210 | Born |
  | 9264410 | Workshop on Martian Sulfates as Recorders of Atmospheric-Fluid Rock Interactions |
  | 28297 | The birds of the Belgian Congo |
  | 8036458 | Intervention strategies to follow informal reading inventory assessment |
  | 8881455 | Solidarity Economy and Social Business |
  | 1754680 | Institutional meat purchase specifications for fresh beef |
  | 3662401 | A sea-fight |
  | 8400743 | 珍藏毛泽东 / Zhen cang Mao Zedong |
  | 4870275 | Nature |
  | 10713653 | The basketball game |
  | 7405862 | CHEME 4620 |
  | 1889884 | Chicken and egg |
  | 3795347 | Beefsteak Raid |
  | 3980062 | 100 Vietnamese painters & sculptors |
  | 7690221 | International Criminal Court, Article 98 |
  | 4721032 | The £ & the $ |
  | 1807908 | Combinatorial algorithms |
