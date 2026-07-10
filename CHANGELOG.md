# Changelog

## 2026-07-09 - Sprint release (dev -> main)

### 🚀 Features

- Make PUI ArchivesSpace finding aid link more visible as a button and remove duplicate finding aid links by @sarah-cul in [#2492](https://github.com/cul-it/blacklight-cornell/pull/2492) ([DACCESS-796](https://culibrary.atlassian.net/browse/DACCESS-796), [DACCESS-300](https://culibrary.atlassian.net/browse/DACCESS-300)) (#2492)

### 🧰 Maintenance

- Add data-location and data-call-number attributes to item holdings for ILLiad add-on integration by @Baroquem in [#2491](https://github.com/cul-it/blacklight-cornell/pull/2491) ([DACCESS-373](https://culibrary.atlassian.net/browse/DACCESS-373)) (#2491)
- Update gems and bump Ruby to 3.4.10 to address flagged security vulnerabilities by @chrisrlc in [#2493](https://github.com/cul-it/blacklight-cornell/pull/2493) ([DACCESS-930](https://culibrary.atlassian.net/browse/DACCESS-930)) (#2493)


## 2026-05-11 - Sprint release (dev -> main)

### 🚀 Features

- Update Requests and My Account gem versions to pull in latest changes and Rails 8 compatibility updates by @Baroquem in [#2479](https://github.com/cul-it/blacklight-cornell/pull/2479) ([DACCESS-849](https://culibrary.atlassian.net/browse/DACCESS-849), [DACCESS-651](https://culibrary.atlassian.net/browse/DACCESS-651), [DACCESS-741](https://culibrary.atlassian.net/browse/DACCESS-741), [DACCESS-740](https://culibrary.atlassian.net/browse/DACCESS-740), [DACCESS-29](https://culibrary.atlassian.net/browse/DACCESS-29), [DACCESS-15](https://culibrary.atlassian.net/browse/DACCESS-15)) (#2479)
- Add 'Title Begins With' search field to the browse view dropdown by @JeremyDuncan in [#2460](https://github.com/cul-it/blacklight-cornell/pull/2460) ([DACCESS-881](https://culibrary.atlassian.net/browse/DACCESS-881)) (#2460)
- Add automated changelog generation GitHub Actions workflow supporting draft artifacts and CHANGELOG.md updates by @JeremyDuncan in [#2458](https://github.com/cul-it/blacklight-cornell/pull/2458) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2458)
- Add pull request template to standardize PR descriptions with sections for description, related issues, type of change, testing instructions, screenshots, and deployment notes by @JeremyDuncan in [#2455](https://github.com/cul-it/blacklight-cornell/pull/2455) (#2455)

### 🐛 Bug Fixes

- Fix 'View all Catalog results' bento search link to include search_field=all_fields and refactor results link URL encoding by @ebtoner in [#2476](https://github.com/cul-it/blacklight-cornell/pull/2476) ([DACCESS-916](https://culibrary.atlassian.net/browse/DACCESS-916)) (#2476)
- Fix changelog automation workflow to use PR-based tracking and resolve workflow concurrency issue that caused runs to cancel each other by @JeremyDuncan in [#2473](https://github.com/cul-it/blacklight-cornell/pull/2473) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2473)
- Fix asynchronous loading of call number facets when forward slashes are present by moving query sanitization for slashes, backslashes, and double-encoded spaces into SearchBuilder by @ebtoner in [#2472](https://github.com/cul-it/blacklight-cornell/pull/2472) ([DACCESS-882](https://culibrary.atlassian.net/browse/DACCESS-882)) (#2472)
- Fix changelog workflow to read AI release-note instructions from the current branch instead of main by @JeremyDuncan in [#2466](https://github.com/cul-it/blacklight-cornell/pull/2466) (#2466)
- Fix Devise Warden errors in controller specs by including Devise::Test::ControllerHelpers in the Rails helper, restoring expected controller-spec behavior after bookbag state initialization by @JeremyDuncan in [#2465](https://github.com/cul-it/blacklight-cornell/pull/2465) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2465)
- Fix broken browser back button in bento search by removing legacy anchor scroll JavaScript by @mhk33 in [#2463](https://github.com/cul-it/blacklight-cornell/pull/2463) ([DACCESS-868](https://culibrary.atlassian.net/browse/DACCESS-868)) (#2463)
- Fix Book Bag count not displaying until the user visits the bookbag view by initializing bookbag state on page load by @JeremyDuncan in [#2462](https://github.com/cul-it/blacklight-cornell/pull/2462) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2462)

### 🦮 Accessibility

- Fix multiple accessibility issues including empty container elements on item record page, missing list roles on special request forms, email label mismatch, header order, and keyboard accessibility for disabled checkboxes by @sarah-cul in [#2467](https://github.com/cul-it/blacklight-cornell/pull/2467) ([DACCESS-896](https://culibrary.atlassian.net/browse/DACCESS-896), [DACCESS-895](https://culibrary.atlassian.net/browse/DACCESS-895), [DACCESS-908](https://culibrary.atlassian.net/browse/DACCESS-908), [DACCESS-898](https://culibrary.atlassian.net/browse/DACCESS-898), [DACCESS-915](https://culibrary.atlassian.net/browse/DACCESS-915)) (#2467)
- Fix selected items list role attribute to update dynamically when items are removed or form is reset by @sarah-cul in [#2475](https://github.com/cul-it/blacklight-cornell/pull/2475) ([DACCESS-895](https://culibrary.atlassian.net/browse/DACCESS-895)) (#2475)
- Fix aria-hidden typo in availability box TOU link icon, resolve SiteImprove italic-in-paragraph error for databases, and replace improper H3 headings with divs for subtitle and author in item view by @mhk33 in [#2456](https://github.com/cul-it/blacklight-cornell/pull/2456) ([DACCESS-899](https://culibrary.atlassian.net/browse/DACCESS-899)) (#2456)
- Change fixed font sizes to relative units in Databases, Digital Collections, Terms of Use, and Footer sections to address SiteImprove AAA accessibility error by @mhk33 in [#2459](https://github.com/cul-it/blacklight-cornell/pull/2459) ([DACCESS-894](https://culibrary.atlassian.net/browse/DACCESS-894)) (#2459)

### 🧰 Maintenance

- Upgrade application to Rails 8, update blacklight-hierarchy gem, bump dependencies, add custom error pages for 422 and 400 responses, and patch Docker Scout vulnerability by @chrisrlc in [#2453](https://github.com/cul-it/blacklight-cornell/pull/2453) ([DACCESS-856](https://culibrary.atlassian.net/browse/DACCESS-856), [DACCESS-887](https://culibrary.atlassian.net/browse/DACCESS-887)) (#2453)
- Bump devise from 5.0.3 to 5.0.4, fixing a security vulnerability (CVE-2026-40295) for open redirect via unvalidated Referer header on session timeout by @dependabot[bot] in [#2478](https://github.com/cul-it/blacklight-cornell/pull/2478) (#2478)
- Update Chromium version, unpin Chromium dependencies, add set -e for early test build error detection, and enable --no-cache flag in Jenkins test builds by @JeremyDuncan in [#2477](https://github.com/cul-it/blacklight-cornell/pull/2477) (#2477)
- Improve changelog workflow to enforce fixed section ordering, newest-to-oldest PR ordering, Created date output, clickable PR links, and PR-based changelog update flow by @JeremyDuncan in [#2468](https://github.com/cul-it/blacklight-cornell/pull/2468) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2468)
- Replace deprecated document_show_fields and render_document_show_field_label with Blacklight's DocumentMetadataComponent in catalog record views by @chrisrlc in [#2461](https://github.com/cul-it/blacklight-cornell/pull/2461) ([DACCESS-824](https://culibrary.atlassian.net/browse/DACCESS-824), [DACCESS-825](https://culibrary.atlassian.net/browse/DACCESS-825)) (#2461)
- Fix flaky Cucumber javascript_loaded test scenarios by ensuring page paths are always root-relative URLs to prevent state-dependent navigation failures by @JeremyDuncan in [#2457](https://github.com/cul-it/blacklight-cornell/pull/2457) ([DACCESS-644](https://culibrary.atlassian.net/browse/DACCESS-644)) (#2457)
- Fix Jenkins CI pipeline and Docker test image to run containers as the Jenkins user so coverage output files have correct permissions and workspace cleanup succeeds by @JeremyDuncan in [#2438](https://github.com/cul-it/blacklight-cornell/pull/2438) ([DACCESS-737](https://culibrary.atlassian.net/browse/DACCESS-737)) (#2438)
- Resolve Blacklight 8 deprecation warnings for query_has_constraints? and filter_params by adopting has_constraints? and filters, and add a safelist of non-public facets to the catalog controller by @ebtoner in [#2401](https://github.com/cul-it/blacklight-cornell/pull/2401) ([DACCESS-750](https://culibrary.atlassian.net/browse/DACCESS-750), [DACCESS-755](https://culibrary.atlassian.net/browse/DACCESS-755)) (#2401)

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
