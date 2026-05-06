# Changelog

## 2026-05-06 - Sprint release (dev -> main)

### 🚀 Features

- Add automated changelog generation GitHub Actions workflow with draft and official modes, plus a release notes style guide by @JeremyDuncan in [#2458](https://github.com/cul-it/blacklight-cornell/pull/2458) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2458)
- Add GitHub pull request template to standardize PR descriptions across the repository by @JeremyDuncan in [#2455](https://github.com/cul-it/blacklight-cornell/pull/2455) (#2455)

### 🐛 Bug Fixes

- Fix changelog workflow to read Copilot release notes instructions from the current branch rather than main by @JeremyDuncan in [#2466](https://github.com/cul-it/blacklight-cornell/pull/2466) (#2466)
- Fix Devise Warden errors in controller specs by including Devise::Test::ControllerHelpers so current_user resolves correctly during testing by @JeremyDuncan in [#2465](https://github.com/cul-it/blacklight-cornell/pull/2465) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2465)
- Fix Book Bag item count to display correctly on all pages immediately after sign-in, not only on the bookbag view by @JeremyDuncan in [#2462](https://github.com/cul-it/blacklight-cornell/pull/2462) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2462)
- Fix intermittent Cucumber test failures for javascript_loaded feature by ensuring page paths are always root-relative by @JeremyDuncan in [#2457](https://github.com/cul-it/blacklight-cornell/pull/2457) ([DACCESS-644](https://culibrary.atlassian.net/browse/DACCESS-644)) (#2457)

### 🦮 Accessibility

- Update fixed font sizes to relative units across Databases, Digital Collections, Terms of Use, and Footer sections to improve accessibility compliance by @mhk33 in [#2459](https://github.com/cul-it/blacklight-cornell/pull/2459) ([DACCESS-894](https://culibrary.atlassian.net/browse/DACCESS-894)) (#2459)
- Fix aria-hidden typo in availability box, resolve italics rendering issue in databases, and correct improper H3 heading usage for subtitle and author on item view by @mhk33 in [#2456](https://github.com/cul-it/blacklight-cornell/pull/2456) ([DACCESS-899](https://culibrary.atlassian.net/browse/DACCESS-899)) (#2456)

### 🧰 Maintenance

- Replace deprecated document_show_fields rendering with DocumentMetadataComponent to resolve Blacklight 8 deprecation warnings on catalog record views by @chrisrlc in [#2461](https://github.com/cul-it/blacklight-cornell/pull/2461) ([DACCESS-824](https://culibrary.atlassian.net/browse/DACCESS-824), [DACCESS-825](https://culibrary.atlassian.net/browse/DACCESS-825)) (#2461)
- Fix Jenkins CI pipeline and Docker test image to run containers as the Jenkins user, resolving workspace cleanup failures caused by root-owned coverage output files by @JeremyDuncan in [#2438](https://github.com/cul-it/blacklight-cornell/pull/2438) ([DACCESS-737](https://culibrary.atlassian.net/browse/DACCESS-737)) (#2438)

# ChangelogSS-7627-b - update to ruby 3.1.2

DISCOVERYACCESS-7446-b - blacklight-cornell-merge-pr job has this line in it:
FOLIO_FEW='http://folio-opac-dev.library.cornell.edu:8983/solr/b2'
Changed that to b3

DISCOVERYACCESS-7194c - useless change to allow retesting

DISCOVERYACCESS-7454-c

## [dev-folio] - 2021-10-01

## [DISCOVERYACCESS-6995] - 2021-03-15
### Changed
DISCOVERYACCESS-6995 - change .env file settings: set SYNDETICS_UNBOUND_ENABLED=1 to turn on Syndetics Table of Contents feature
