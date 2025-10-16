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
  | 1001 | Reflections |
  | 1003756 | Struktura filosofskogo znanii︠a︡ |
  | 10055679 | Big chicken |
  | 10079768 | Zombies |
  | 100999 | Biology of pathogenic fungi |
  | 10292143 | The Charter Oak lawn mower. The Hills "Archimedean" Lawn Mower Company, manufacturer of the "Archimedean" and "Charter Oak" lawn mowers. ... Hartford, Conn |
  | 10294079 | Werke für Militärmusik und Panharmonikon |
  | 10297339 | China across the centuries |
  | 1041597 | Sweet hands |
  | 10470186 | Deśa dukheko belā |
  | 1055784 | Utilisation of the resources of the coal mining industry |
  | 1059732 | Index to congressional committee hearings in the Library of the United States House of Representatives |
  | 106223 | Declaration of a heretic |
  | 10635622 | Sophisticated giant |
  | 10648489 | The most relaxing Beethoven album in the world-- ever! |
  | 1077314 | A constitution for the socialist commonwealth of Great Britain |
  | 10976407 | 100 poems |
  | 11078915 | Cello and Piano Recital: Yamazaki, Nobuko / Kosuge, Yu - MARTINŮ, B. / RACHMANINOV, S. |
  | 11493262 | Scholastici orthodoxi specimen |
  | 11499748 | The first examinacyon of Anne Askewe |
  | 115093 | Tập san nghiên cứu văn sử địa |
  | 115113 | Survey of current business |
  | 115115 | The Soviet journal of nondestructive testing |
  | 115208 | The College cost book |
  | 115235 | IMA journal of applied mathematics |
  | 115317 | Journal of the Inter-American Foundation |
  | 115453 | RIC reviews |
  | 115621 | Zeitschrift für Kunstgeschichte |
  | 115983 | The Economist |
  | 116073 | International wildlife |
  | 116482 | Anuarul statistic al Republicii Socialiste România |
  | 11682760 | West Indies, General, Immigration: 162. No. 2304 Coolie Emigration, Wilson |
  | 118111 | Alabama business |
  | 11830656 | Journal of King Abdulaziz University |
  | 11858499 | ACA-RES |
  | 12055759 | Interactive Storytelling |
  | 120634 | Annulus wall boundary layers in turbomachines |
  | 1208939 | Chi Pheo and other stories |
  | 12235440 | Early Childhood Development Through An Integrated Program: Evidence From The Philippines |
  | 12384447 | Mutual misunderstanding |
  | 12443541 | Magic lantern slide: The Prince Albert at Hendon |
  | 12473094 | Algebras and orders |
  | 12486234 | William Penn |
  | 12508359 | Absolute Obstetric Anesthesia Review |
  | 12769773 | Laïcité, laïcités |
  | 12939110 | The self and self-knowledge |
  | 13014041 | Wholesale catalogue : fall and spring 1894-5 : bulbs and nursery stock |
  | 130786 | Manual of the trees of North America (exclusive of Mexico) |
  | 13131518 | Roman colonies in republic and empire |
  | 13156934 | 19th Annual North American Waste-to-Energy Conference |
  | 13185411 | The royal inscriptions of Tiglath-pileser III (744-727 BC) and Shalmaneser V (726-722 BC), kings of Assyria |
  | 13251647 | Promoting inclusion |
  | 13251848 | Keeping the lights on |
  | 1378974 | Educating for world consciousness in the sixth grade |
  | 1497884 | Neue Architektur in Freiburg |
  | 1535861 | The annotated Hobbit |
  | 1545844 | The New York times |
  | 1630516 | An Anthology of Chartist poetry |
  | 168319 | Actes du consistoire de l'Église française de Threadneedle street, Londres ... |
  | 1754680 | Institutional meat purchase specifications for fresh beef |
  | 1807908 | Combinatorial algorithms |
  | 1889884 | Chicken and egg |
  | 1921175 | Handlangers van de vijand |
  | 1976578 | The Vietnam war |
  | 2070362 | Kramer family papers |
  | 2073985 | Cornell University Graduate School student records |
  | 2083253 | George Burr Upton papers |
  | 211313 | Australien nach dem stande der geographischen kenntniss in 1871 |
  | 2117105 | Ūʺ krīʺ Bha Thuikʻ, suiʹ ma hutʻ muiʺ nhaṅʻʹ mre kui ʼoṅʻ nuiṅʻ khraṅʻʺ |
  | 2144728 | Polymer chemistry |
  | 2229355 | Agricultural schedules of New York State by counties |
  | 2329334 | Mayvale |
  | 2393100 | Hindi ko akalain |
  | 247316 | The cheese and the worms |
  | 2533260 | Het Koloniaal Instituut te Amsterdam, wording, werking en toekomst |
  | 259600 | Diversification through acquisition |
  | 2612850 | Matumalar |
  | 264095 | Christian advocate |
  | 2659255 | Introduction a l'histoire |
  | 2696727 | Race, ethnicity and multiculturalism |
  | 2719151 | Plantas útiles de la Amazonia peruana |
  | 274568 | El diablo sin querer hizo un santo |
  | 277880 | An historical and critical account of the life and writing of the ever-memorable Mr. John Hales ... |
  | 2795276 | The Malott times |
  | 2805041 | Carly Simon's Romulus Hunt |
  | 28297 | The birds of the Belgian Congo |
  | 285282 | Human rights quarterly |
  | 2871980 | Housing & suburbs |
  | 2891538 | The fatal frontier |
  | 2917297 | Strategi dan implikasi pendidikan "Panti Sosial Bina Remaja Putra Terbaik" Palu, terhadap pembinaan sikap mental peserta didik |
  | 298714 | The Academy of Management review |
  | 30000 | Impact of budget proposals on income maintenance programs, trade and economic policy, state and local issues |
  | 300640 | Archives of mechanics |
  | 301363 | Biology |
  | 306998 | Municipal innovations |
  | 3158956 | Systematics of Erisma (Vochysiaceae) |
  | 3261564 | Debabrata Biśvāsa |
  | 329763 | Nature |
  | 330333 | Ithaca times |
  | 361984 | The annual of the British school at Athens |
  | 3624983 | They fought for the sky |
  | 3662401 | A sea-fight |
  | 368665 | The International directory of computer and information system services |
  | 3709643 | Mawsūʻat al-ʻimārah wa-funūn al-Islāmīyah |
  | 3733929 | The British in Capri, 1806-1808 |
  | 3749 | Convexity and duality in optimization |
  | 3795347 | Beefsteak Raid |
  | 38097 | Encyclopedia of railroading |
  | 3849306 | Harry Potter and the goblet of fire |
  | 3855887 | Harry Potter und der Feuerkelch |
  | 3856962 | Harry Potter and the goblet of fire |
  | 3980062 | 100 Vietnamese painters & sculptors |
  | 3994650 | Howards End |
  | 4073823 | Birds I have kept in years gone by |
  | 4163301 | Harry Potter og eldbikarinn |
  | 4260049 | A journal of La Salle's last voyage |
  | 4274784 | Nihon bunkashi handobukku |
  | 44112 | This sex which is not one |
  | 4442 | Lives of Alexander Wilson and Captain John Smith |
  | 4473308 | Confessio fidei exhibita invictiss. imp. Carolo V. Caesari Aug. in comicijs Augustae. Anno MDXXX ; Addita est Apologia co[n]fessionis ; Psalm 119 ; Et loquebar de testimoniis tuis in conspectu Regum, & non consundebar |
  | 4481177 | AnthropologyPlus |
  | 45766 | Proceedings of the ... Convention, Graphic Communications International Union |
  | 4626 | D.H. Lawrence |
  | 4629 | Das Selbstbestimmungsrecht der Völker und die Sowjetunion |
  | 4652717 | Saint-Jean-des-Vignes in Soissons |
  | 4684601 | Der Anteil der Plastik an der Entstehung der griechischen Götterwelt und die Athene des Phidias |
  | 4719839 | The sweet science |
  | 4721032 | The £ & the $ |
  | 4723 | Handbuch der Mineralogie |
  | 4745264 | The great delusion |
  | 4759 | Mangrāisāt chabap Chīangman, tonchabap Wat Chīangman, ʻAmphœ̄ Mư̄ang, Čhangwat Chīang Mai |
  | 4767 | Introduction to the study of international law |
  | 4768 | Xây dựng và nhân điển hình |
  | 4811235 | Abkürzungen und Schriftbesonderheiten in der Frühen Neuzeit aus altwürttembergischen Quellen |
  | 4870275 | Nature |
  | 4957578 | Romantische Kommunikation |
  | 499380 | Ocean thermal energy conversion |
  | 5094470 | Plan of Franklinville, in Mason County, Kentucky |
  | 5146902 | KMODDL |
  | 5192841 | An appendix to the account of Italy, in answer to Samuel Sharp, Esq; by Joseph Baretti |
  | 5230676 | Paine's four letters. Letters on government: including both his letters to Mr. Dundas; with two letters to Lord Onslow, and two from Paris. By Thomas Paine, ... to which are prefixed anecdotes of his life |
  | 52325 | Bonsai |
  | 5250067 | A correct statement of the grand cricket-match, played at Worksop, on Monday, Tuesday, and Wednesday, the 3d, 4th, and 5th of November 1800, by eleven members of the Nottingham Club, against twenty-two members of the Sheffield Club, for two hundred guineas |
  | 5282949 | The debtor and creditor's assistant |
  | 5318858 | Sexual orientation and the law |
  | 5346517 | ARTstor |
  | 5380314 | The New York times |
  | 5458505 | Beautiful birds |
  | 5582519 | A treatise on the jurisdiction and proceedings of the justices of the peace, in civil suits |
  | 5727137 | Hārī Pūtir wa-kaʼs al-nār |
  | 5729532 | Mac OS X Tiger in a nutshell |
  | 5784288 | Stravinsky |
  | 5820954 | Encyclopedia of pain |
  | 5861952 | Artefacts Canada |
  | 586840 | A classification scheme for client problems in community health nursing |
  | 595322 | Aesthetic experience and literary hermeneutics |
  | 5972895 | Chính sách tôn giáo của Đảng |
  | 5993865 | Massachusetts, Rhode Island, and Connecticut |
  | 6041 | Encyclical letter of Pope Pius XII, October 20, 1939 |
  | 6044052 | Perfect girls, starving daughters |
  | 6057007 | Resumen del programa Medicare |
  | 6060112 | Household discoveries |
  | 608 | U.S. coal goes abroad |
  | 6112378 | The Kalabagh Dam |
  | 6202761 | Animēshon no rinshō shinrigaku |
  | 631947 | Growing against ourselves: the energy-environment tangle |
  | 6395180 | 100% beef |
  | 6417953 | Abbott's encyclopedia of rope tricks for magicians |
  | 6632477 | Purple rain |
  | 6701 | Birds of the Bahamas |
  | 6714412 | The Resonant Body Transistor |
  | 6729449 | Hourly observations and experimental investigations on the barometer |
  | 67466 | Indian Ocean and regional security |
  | 6810431 | Birds I have kept in years gone by |
  | 6829468 | Meiguo xue zhe lun Meiguo Zhongguo xue |
  | 6926604 | Click |
  | 6943906 | Chigu shi chao |
  | 6946453 | Black Studies Center |
  | 705681 | Pflanzensoziologische Exkursionsflora für Südwestdeutschland und die angrenzenden Gebiete |
  | 7056812 | Do it anyway |
  | 713666 | Hướng dẩn học sinh Việt Nam Trung học đệ I cấp |
  | 7142756 | 10 nam nhin lai |
  | 721607 | World population |
  | 7405862 | CHEME 4620 |
  | 7571753 | Hyāri Paṭāra ayāṇḍa dya gabaleṭa aba phāẏāra |
  | 7644460 | Medicare |
  | 7690221 | International Criminal Court, Article 98 |
  | 784742 | Los indios eran muy penetrantes |
  | 7899862 | Discourse on sacred and profane images |
  | 7935065 | Rechevai︠a︡ kommunikat︠s︡ii︠a︡ |
  | 7943432 | The basic practice of statistics |
  | 7981095 | Shelter medicine for veterinarians and staff |
  | 8013020 | Sir William Dunbar and Sir Alexander Grant, baronets, Duncan Urquhart and Alexander Tulloch, Esquires, appellants, Alexander Brodie of Lethen, Esquire, respondent |
  | 8036458 | Intervention strategies to follow informal reading inventory assessment |
  | 8212979 | Ancient libraries |
  | 8215832 | Topographies of fascism |
  | 8251908 | Highway safety: federal and state efforts related to accidents that involve non-commercial vehicles carrying unsecured loads |
  | 8258651 | ʻAnusō̜n ngān phrarātchathān phlœ̄ng sop Sātsatrāčhān (Phisēt) Dō̜rō̜. Kamthō̜n Sathirakun Pō̜. Mō̜., Thō̜. Chō̜ |
  | 8272732 | The goldfinch |
  | 8297109 | Kammermusik mit Blasinstrumenten |
  | 8320680 | Is base realignment and closure (BRAC) appropriate at this time? |
  | 8400743 | Zhen cang Mao Zedong |
  | 8405575 | Zhuan xing, sheng ji yu chuang xin |
  | 8515796 | Darwīshat waraq |
  | 8532009 | CARTER, E.: Edition, Vol. 7 - Dialogues / Boston Concerto / Cello Concerto / ASKO Concerto (Knussen) |
  | 8570795 | ZELTER, C.F.: Goethe-Lieder, Vol. 1 (Mammel) |
  | 8623 | Dokumente zur Deutschlandpolitik |
  | 8688843 | Beyond inclusion |
  | 8694359 | Instituciones practicas de los juicios civiles, asi ordinarios como extraordinarios, en todos sus tramites, segun que se emplezan, continuan y acaban en los tribunales reales |
  | 8753977 | Kenneth A. R. Kennedy papers |
  | 8797135 | Gale |
  | 8816169 | Greek papyri from Montserrat (P.Monts.Roca IV) |
  | 8910490 | Overruled |
  | 8913436 | AHA annual survey database |
  | 8918300 | Hǣri Phō̜ttœ̄ kap thūai ʻakkhanī |
  | 8948570 | Attacking trigonometry problems |
  | 907865 | Africa and the novel |
  | 9134804 | Medien der Theatergeschichte des 18. und 19. Jahrhunderts |
  | 9201061 | Race, ideology, and the decline of Caribbean Marxism |
  | 9203210 | Born |
  | 9264410 | Workshop on Martian Sulfates as Recorders of Atmospheric-Fluid Rock Interactions |
  | 939735 | Deutsche Demokratische Republik |
  | 9668414 | Now that we're men |
  | 9748547 | Chamber Music - LALLIET, C.-T. / DRING, M. / PARR, P. / HOPE, P. (Three Wood Trio) |
  | 9898648 | Harry Potter et la coupe de feu |
  | 996135 | Whipped cream & other delights |
  | 16387366 | Music time USA |
  | 10573914 | The best of 2014 |