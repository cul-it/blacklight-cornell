# encoding: utf-8
@folio
Feature: Language Support
  In order to test FOLIO with a subset of catalog records
  As a developer
  I want to confirm multiple languages are well supported

Scenario Outline: Show titles in their native language
    Given I request the item view for <bibid>
    Then I should see the label '<title>'

Examples:
    | bibid | title |
    | 6829468 | 美国学者论美国中国学 / Meiguo xue zhe lun Meiguo Zhongguo xue |
    | 8405575 | 转型、升级与创新 / Zhuan xing, sheng ji yu chuang xin |
    | 8918300 | แฮรี่ พอตเตอร์กับถ้วยอัคนี / Hǣri Phō̜ttœ̄ kap thūai ʻakkhanī |
    | 8258651 | อนุสรณ์งานพระราชทานเพลิงศพ ศาสตราจารย์ (พิเศษ) ดร. กำธร สถิรกุล ป.ม., ท.ช / ʻAnusō̜n ngān phrarātchathān phlœ̄ng sop Sātsatrāčhān (Phisēt) Dō̜rō̜. Kamthō̜n Sathirakun Pō̜. Mō̜., Thō̜. Chō̜ |
