# Changelog

## 2026-05-08 - Sprint release (dev -> main)

### 🚀 Features

- Add 'Title Begins With' search field to the browse view dropdown by @JeremyDuncan in [#2460](https://github.com/cul-it/blacklight-cornell/pull/2460) ([DACCESS-881](https://culibrary.atlassian.net/browse/DACCESS-881)) (#2460)
- Add automated changelog generation GitHub Actions workflow with Copilot release notes by @JeremyDuncan in [#2458](https://github.com/cul-it/blacklight-cornell/pull/2458) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2458)
- Add PR template to standardize pull request descriptions across the repository by @JeremyDuncan in [#2455](https://github.com/cul-it/blacklight-cornell/pull/2455) (#2455)

### 🐛 Bug Fixes

- Fix changelog automation concurrency issue and update workflow to use PR-based changelog updates for active dev→main releases by @JeremyDuncan in [#2473](https://github.com/cul-it/blacklight-cornell/pull/2473) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2473)
- Fix call number facet async loading when search queries contain forward slashes by moving query sanitization into SearchBuilder by @ebtoner in [#2472](https://github.com/cul-it/blacklight-cornell/pull/2472) ([DACCESS-882](https://culibrary.atlassian.net/browse/DACCESS-882)) (#2472)
- Fix changelog workflow to read release-note instructions from the current branch instead of main by @JeremyDuncan in [#2466](https://github.com/cul-it/blacklight-cornell/pull/2466) (#2466)
- Fix Warden-related controller spec failures by including Devise test helpers for controller-type specs by @JeremyDuncan in [#2465](https://github.com/cul-it/blacklight-cornell/pull/2465) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2465)
- Fix back button behavior in bento search by removing legacy anchor scroll JavaScript by @mhk33 in [#2463](https://github.com/cul-it/blacklight-cornell/pull/2463) ([DACCESS-868](https://culibrary.atlassian.net/browse/DACCESS-868)) (#2463)
- Fix Book Bag count not displaying on the homepage until user visits the bookbag view by @JeremyDuncan in [#2462](https://github.com/cul-it/blacklight-cornell/pull/2462) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2462)

### 🦮 Accessibility

- Fix multiple accessibility issues on item record and special request form pages including empty container elements, form label mismatches, keyboard accessibility, and heading order by @sarah-cul in [#2467](https://github.com/cul-it/blacklight-cornell/pull/2467) ([DACCESS-896](https://culibrary.atlassian.net/browse/DACCESS-896), [DACCESS-895](https://culibrary.atlassian.net/browse/DACCESS-895), [DACCESS-908](https://culibrary.atlassian.net/browse/DACCESS-908), [DACCESS-898](https://culibrary.atlassian.net/browse/DACCESS-898), [DACCESS-915](https://culibrary.atlassian.net/browse/DACCESS-915)) (#2467)
- Change fixed font sizes to relative units in Databases, Digital Collections, Terms of Use, and Footer sections to address AAA accessibility standards by @mhk33 in [#2459](https://github.com/cul-it/blacklight-cornell/pull/2459) ([DACCESS-894](https://culibrary.atlassian.net/browse/DACCESS-894)) (#2459)
- Fix aria-hidden typo in availability box, incorrect italics markup in databases, and improper heading usage for subtitle and author on the item view page by @mhk33 in [#2456](https://github.com/cul-it/blacklight-cornell/pull/2456) ([DACCESS-899](https://culibrary.atlassian.net/browse/DACCESS-899)) (#2456)

### 🧰 Maintenance

- Update Chromium version, unpin Chromium dependencies, and add --no-cache Docker build support to resolve test environment build failures by @JeremyDuncan in [#2477](https://github.com/cul-it/blacklight-cornell/pull/2477) (#2477)
- Improve Copilot changelog workflow with PR-based changelog updates, consistent section ordering, newest-to-oldest PR ordering, and automated changelog PR creation by @JeremyDuncan in [#2468](https://github.com/cul-it/blacklight-cornell/pull/2468) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2468)
- Replace deprecated document_show_fields with Blacklight's MetadataFieldComponent for catalog record display by @chrisrlc in [#2461](https://github.com/cul-it/blacklight-cornell/pull/2461) ([DACCESS-824](https://culibrary.atlassian.net/browse/DACCESS-824), [DACCESS-825](https://culibrary.atlassian.net/browse/DACCESS-825)) (#2461)
- Fix intermittent test failures in the javascript_loaded feature by ensuring page paths are always root-relative by @JeremyDuncan in [#2457](https://github.com/cul-it/blacklight-cornell/pull/2457) ([DACCESS-644](https://culibrary.atlassian.net/browse/DACCESS-644)) (#2457)
- Upgrade application to Rails 8, update gem dependencies including Blacklight hierarchy, and add custom error pages for 422 and 400 responses by @chrisrlc in [#2453](https://github.com/cul-it/blacklight-cornell/pull/2453) ([DACCESS-856](https://culibrary.atlassian.net/browse/DACCESS-856), [DACCESS-887](https://culibrary.atlassian.net/browse/DACCESS-887)) (#2453)
- Fix Jenkins CI pipeline to run test containers as the Jenkins user, preventing file permission errors during workspace cleanup by @JeremyDuncan in [#2438](https://github.com/cul-it/blacklight-cornell/pull/2438) ([DACCESS-737](https://culibrary.atlassian.net/browse/DACCESS-737)) (#2438)

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
