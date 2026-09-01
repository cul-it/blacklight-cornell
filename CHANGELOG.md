# Changelog

## 2026-09-01 - Sprint release (dev -> main)

### 🚀 Features

- Fix sign-in redirect losing your search results page and improve development log formatting by @JeremyDuncan in [#2529](https://github.com/cul-it/blacklight-cornell/pull/2529) ([DACCESS-1000](https://culibrary.atlassian.net/browse/DACCESS-1000)) (#2529)
- Add AND labeling to advanced search constraints for clearer facet combinations by @ebtoner in [#2521](https://github.com/cul-it/blacklight-cornell/pull/2521) ([DACCESS-638](https://culibrary.atlassian.net/browse/DACCESS-638)) (#2521)
- Suppress request buttons for Digital CoLab items by @Baroquem in [#2505](https://github.com/cul-it/blacklight-cornell/pull/2505) ([DACCESS-216](https://culibrary.atlassian.net/browse/DACCESS-216)) (#2505)
- Add fallback link and abstract text for research guide results in bento search by @ebtoner in [#2512](https://github.com/cul-it/blacklight-cornell/pull/2512) ([DACCESS-969](https://culibrary.atlassian.net/browse/DACCESS-969)) (#2512)

### 🐛 Bug Fixes

- Exclude non-public facets from Solr requests to improve search performance by @ebtoner in [#2525](https://github.com/cul-it/blacklight-cornell/pull/2525) ([DACCESS-750](https://culibrary.atlassian.net/browse/DACCESS-750)) (#2525)
- Refine search results, browse, and general UI spacing and responsiveness by @mhk33 in [#2523](https://github.com/cul-it/blacklight-cornell/pull/2523) ([DACCESS-986](https://culibrary.atlassian.net/browse/DACCESS-986)) (#2523)
- Show correct request buttons on ArchivesSpace items with circulating holdings by @sarah-cul in [#2517](https://github.com/cul-it/blacklight-cornell/pull/2517) ([DACCESS-961](https://culibrary.atlassian.net/browse/DACCESS-961)) (#2517)
- Fix remaining blacklight-hierarchy icon and spacing styling issues by @ebtoner in [#2524](https://github.com/cul-it/blacklight-cornell/pull/2524) ([DACCESS-968](https://culibrary.atlassian.net/browse/DACCESS-968)) (#2524)
- Upgrade blacklight-hierarchy to 6.9.0, removing its jQuery dependency and updating icon styling by @chrisrlc in [#2518](https://github.com/cul-it/blacklight-cornell/pull/2518) ([DACCESS-968](https://culibrary.atlassian.net/browse/DACCESS-968)) (#2518)
- Hide the Looking
for
more? sidebar on zero-result catalog searches by @chrisrlc in [#2519](https://github.com/cul-it/blacklight-cornell/pull/2519) ([DACCESS-983](https://culibrary.atlassian.net/browse/DACCESS-983)) (#2519)
- Fix broken catalog record emails caused by a search field regression by @chrisrlc in [#2516](https://github.com/cul-it/blacklight-cornell/pull/2516) ([DACCESS-978](https://culibrary.atlassian.net/browse/DACCESS-978)) (#2516)
- Restore the Apply button on the publication year facet and fix advanced search error placement by @chrisrlc in [#2515](https://github.com/cul-it/blacklight-cornell/pull/2515) ([DACCESS-975](https://culibrary.atlassian.net/browse/DACCESS-975)) (#2515)
- Update My Account to add Bootstrap 5 support and fix a login bug by @chrisrlc in [#2514](https://github.com/cul-it/blacklight-cornell/pull/2514) ([DACCESS-961](https://culibrary.atlassian.net/browse/DACCESS-961), [DACCESS-970](https://culibrary.atlassian.net/browse/DACCESS-970)) (#2514)
- Upgrade Blacklight to v8.12.3 and fix bookbag checkboxes not persisting after refresh by @chrisrlc in [#2507](https://github.com/cul-it/blacklight-cornell/pull/2507) ([DACCESS-739](https://culibrary.atlassian.net/browse/DACCESS-739), [DACCESS-942](https://culibrary.atlassian.net/browse/DACCESS-942)) (#2507)
- Return consistent basic search results by defaulting to all-fields search when none is specified by @ebtoner in [#2502](https://github.com/cul-it/blacklight-cornell/pull/2502) ([DACCESS-917](https://culibrary.atlassian.net/browse/DACCESS-917)) (#2502)

### 🦮 Accessibility

- Remove unsupported aria-labels on div elements to resolve accessibility issues by @sarah-cul in [#2509](https://github.com/cul-it/blacklight-cornell/pull/2509) ([DACCESS-955](https://culibrary.atlassian.net/browse/DACCESS-955)) (#2509)

### 🧰 Maintenance

- Clean up footer, item tools, and bookbag debug styling by @mhk33 in [#2527](https://github.com/cul-it/blacklight-cornell/pull/2527) ([DACCESS-986](https://culibrary.atlassian.net/browse/DACCESS-986)) (#2527)
- Remove obsolete spinner libraries and legacy holdings/backend code by @Baroquem in [#2526](https://github.com/cul-it/blacklight-cornell/pull/2526) ([DACCESS-977](https://culibrary.atlassian.net/browse/DACCESS-977), [DACCESS-988](https://culibrary.atlassian.net/browse/DACCESS-988)) (#2526)
- Improve print layout spacing and clean up Aeon print styles by @mhk33 in [#2520](https://github.com/cul-it/blacklight-cornell/pull/2520) ([DACCESS-984](https://culibrary.atlassian.net/browse/DACCESS-984)) (#2520)
- Upgrade Rails to 8.1 and update Ruby gems to resolve dependency alerts by @chrisrlc in [#2510](https://github.com/cul-it/blacklight-cornell/pull/2510) ([DACCESS-939](https://culibrary.atlassian.net/browse/DACCESS-939)) (#2510)
- Update Aeon request forms to Bootstrap 5, fixing excessive scrolling on items with many holdings by @sarah-cul in [#2513](https://github.com/cul-it/blacklight-cornell/pull/2513) ([DACCESS-918](https://culibrary.atlassian.net/browse/DACCESS-918)) (#2513)
- Upgrade Bootstrap from v4 to v5 by @chrisrlc in [#2511](https://github.com/cul-it/blacklight-cornell/pull/2511) ([DACCESS-918](https://culibrary.atlassian.net/browse/DACCESS-918)) (#2511)
- Remove the survey button from bento search pages by @mhk33 in [#2508](https://github.com/cul-it/blacklight-cornell/pull/2508) ([DACCESS-959](https://culibrary.atlassian.net/browse/DACCESS-959)) (#2508)
- Update LibGuides API integration to v1.2 with token caching and improved guide search relevance by @ebtoner in [#2506](https://github.com/cul-it/blacklight-cornell/pull/2506) ([DACCESS-940](https://culibrary.atlassian.net/browse/DACCESS-940)) (#2506)
- Enable eager loading of classes in production for improved performance by @chrisrlc in [#2503](https://github.com/cul-it/blacklight-cornell/pull/2503) ([DACCESS-935](https://culibrary.atlassian.net/browse/DACCESS-935)) (#2503)
- Remove legacy Elastic Beanstalk configuration files by @chrisrlc in [#2504](https://github.com/cul-it/blacklight-cornell/pull/2504) (#2504)
- Update Requests and My Account gems to their latest releases by @Baroquem in [#2528](https://github.com/cul-it/blacklight-cornell/pull/2528) (#2528)


### Needs Review
- 🧰 Maintenance Bump blacklight_cornell_requests to the latest dev revision by @chrisrlc in [#2522](https://github.com/cul-it/blacklight-cornell/pull/2522) (#2522) — _PR body has no 'Type of Change' checkboxes filled in, so category is inferred as Maintenance per team default._

## 2026-09-01 - Sprint release (dev -> main)

### 🚀 Features

- Add AND prefix to advanced search constraint labels to clarify combined facet filters by @ebtoner in [#2521](https://github.com/cul-it/blacklight-cornell/pull/2521) ([DACCESS-638](https://culibrary.atlassian.net/browse/DACCESS-638)) (#2521)
- Hide request buttons on Digital CoLab item records and clean up duplicate button IDs by @Baroquem in [#2505](https://github.com/cul-it/blacklight-cornell/pull/2505) ([DACCESS-216](https://culibrary.atlassian.net/browse/DACCESS-216)) (#2505)
- Add fallback link and description fields so research guide bento results no longer appear broken by @ebtoner in [#2512](https://github.com/cul-it/blacklight-cornell/pull/2512) ([DACCESS-969](https://culibrary.atlassian.net/browse/DACCESS-969)) (#2512)

### 🐛 Bug Fixes

- Fix sign-in redirecting to a broken internal facet URL instead of back to your search results by @JeremyDuncan in [#2529](https://github.com/cul-it/blacklight-cornell/pull/2529) ([DACCESS-1000](https://culibrary.atlassian.net/browse/DACCESS-1000)) (#2529)
- Exclude non-public facets from search requests to reduce Solr response times by @ebtoner in [#2525](https://github.com/cul-it/blacklight-cornell/pull/2525) ([DACCESS-750](https://culibrary.atlassian.net/browse/DACCESS-750)) (#2525)
- Improve search results layout, facet spacing, and browse page styling for Bootstrap 5 by @mhk33 in [#2523](https://github.com/cul-it/blacklight-cornell/pull/2523) ([DACCESS-986](https://culibrary.atlassian.net/browse/DACCESS-986)) (#2523)
- Show the Request item button for Aspace records that also have circulating holdings by @sarah-cul in [#2517](https://github.com/cul-it/blacklight-cornell/pull/2517) ([DACCESS-961](https://culibrary.atlassian.net/browse/DACCESS-961)) (#2517)
- Fix spacing and icon placement issues in the location and call number hierarchy facets by @ebtoner in [#2524](https://github.com/cul-it/blacklight-cornell/pull/2524) ([DACCESS-968](https://culibrary.atlassian.net/browse/DACCESS-968)) (#2524)
- Upgrade blacklight-hierarchy to 6.9.0, removing its jQuery dependency and updating icon styling by @chrisrlc in [#2518](https://github.com/cul-it/blacklight-cornell/pull/2518) ([DACCESS-968](https://culibrary.atlassian.net/browse/DACCESS-968)) (#2518)
- Remove the Looking
for
more? sidebar from search results pages that return zero results by @chrisrlc in [#2519](https://github.com/cul-it/blacklight-cornell/pull/2519) ([DACCESS-983](https://culibrary.atlassian.net/browse/DACCESS-983)) (#2519)
- Fix the record Email feature that broke when no search_field is provided in a query by @chrisrlc in [#2516](https://github.com/cul-it/blacklight-cornell/pull/2516) ([DACCESS-978](https://culibrary.atlassian.net/browse/DACCESS-978)) (#2516)
- Restore the Apply button and fix error message placement in the publication year range facet by @chrisrlc in [#2515](https://github.com/cul-it/blacklight-cornell/pull/2515) ([DACCESS-975](https://culibrary.atlassian.net/browse/DACCESS-975)) (#2515)
- Update the My Account library to fix a login bug and add Bootstrap 5 support by @chrisrlc in [#2514](https://github.com/cul-it/blacklight-cornell/pull/2514) ([DACCESS-961](https://culibrary.atlassian.net/browse/DACCESS-961), [DACCESS-970](https://culibrary.atlassian.net/browse/DACCESS-970)) (#2514)
- Upgrade Blacklight to v8.12.3, fixing bookbag checkbox selections lost on page refresh by @chrisrlc in [#2507](https://github.com/cul-it/blacklight-cornell/pull/2507) ([DACCESS-739](https://culibrary.atlassian.net/browse/DACCESS-739), [DACCESS-942](https://culibrary.atlassian.net/browse/DACCESS-942)) (#2507)
- Make basic search queries consistently default to searching all fields when none is specified by @ebtoner in [#2502](https://github.com/cul-it/blacklight-cornell/pull/2502) ([DACCESS-917](https://culibrary.atlassian.net/browse/DACCESS-917)) (#2502)

### 🦮 Accessibility

- Remove unsupported aria-label attributes from div elements to resolve accessibility scan errors by @sarah-cul in [#2509](https://github.com/cul-it/blacklight-cornell/pull/2509) ([DACCESS-955](https://culibrary.atlassian.net/browse/DACCESS-955)) (#2509)

### 🧰 Maintenance

- Update Requests and My Account to their latest releases (5.6 and 2.6) by @Baroquem in [#2528](https://github.com/cul-it/blacklight-cornell/pull/2528) (#2528)
- Clean up footer, item tools, and bookbag debug styling for consistency with Bootstrap 5 by @mhk33 in [#2527](https://github.com/cul-it/blacklight-cornell/pull/2527) ([DACCESS-986](https://culibrary.atlassian.net/browse/DACCESS-986)) (#2527)
- Remove obsolete spinner libraries and legacy holdings/backend code no longer in use by @Baroquem in [#2526](https://github.com/cul-it/blacklight-cornell/pull/2526) ([DACCESS-977](https://culibrary.atlassian.net/browse/DACCESS-977), [DACCESS-988](https://culibrary.atlassian.net/browse/DACCESS-988)) (#2526)
- Update blacklight_cornell_requests to the latest development version by @chrisrlc in [#2522](https://github.com/cul-it/blacklight-cornell/pull/2522) (#2522)
- Improve print layout spacing and add dedicated print styles for Aeon request pages by @mhk33 in [#2520](https://github.com/cul-it/blacklight-cornell/pull/2520) ([DACCESS-984](https://culibrary.atlassian.net/browse/DACCESS-984)) (#2520)
- Upgrade Rails to 8.1 and update dependencies to resolve dependabot security alerts by @chrisrlc in [#2510](https://github.com/cul-it/blacklight-cornell/pull/2510) ([DACCESS-939](https://culibrary.atlassian.net/browse/DACCESS-939)) (#2510)
- Update Aeon request forms to Bootstrap 5 and fix excess page scrolling on holdings checkboxes by @sarah-cul in [#2513](https://github.com/cul-it/blacklight-cornell/pull/2513) ([DACCESS-918](https://culibrary.atlassian.net/browse/DACCESS-918)) (#2513)
- Upgrade Bootstrap from v4 to v5 and replace bootbox.js with native Bootstrap modals by @chrisrlc in [#2511](https://github.com/cul-it/blacklight-cornell/pull/2511) ([DACCESS-918](https://culibrary.atlassian.net/browse/DACCESS-918)) (#2511)
- Remove the survey button from bento search pages by @mhk33 in [#2508](https://github.com/cul-it/blacklight-cornell/pull/2508) ([DACCESS-959](https://culibrary.atlassian.net/browse/DACCESS-959)) (#2508)
- Update the LibGuides API integration to v1.2 with OAuth token caching and improved search relevance by @ebtoner in [#2506](https://github.com/cul-it/blacklight-cornell/pull/2506) ([DACCESS-940](https://culibrary.atlassian.net/browse/DACCESS-940)) (#2506)
- Enable eager loading of classes in production and integration environments to improve boot performance by @chrisrlc in [#2503](https://github.com/cul-it/blacklight-cornell/pull/2503) ([DACCESS-935](https://culibrary.atlassian.net/browse/DACCESS-935)) (#2503)
- Remove unused legacy Elastic Beanstalk configuration files by @chrisrlc in [#2504](https://github.com/cul-it/blacklight-cornell/pull/2504) (#2504)

## 2026-07-09 - Sprint release (dev -> main)

### 🚀 Features

- Make PUI ArchivesSpace finding aid link more visible as a button and remove duplicate finding aid links by @sarah-cul in [#2492](https://github.com/cul-it/blacklight-cornell/pull/2492) ([DACCESS-796](https://culibrary.atlassian.net/browse/DACCESS-796), [DACCESS-300](https://culibrary.atlassian.net/browse/DACCESS-300)) (#2492)

### 🧰 Maintenance

- Add data-location and data-call-number attributes to item holdings for ILLiad add-on integration by @Baroquem in [#2491](https://github.com/cul-it/blacklight-cornell/pull/2491) ([DACCESS-373](https://culibrary.atlassian.net/browse/DACCESS-373)) (#2491)
- Update gems and bump Ruby to 3.4.10 to address flagged security vulnerabilities by @chrisrlc in [#2493](https://github.com/cul-it/blacklight-cornell/pull/2493) ([DACCESS-930](https://culibrary.atlassian.net/browse/DACCESS-930)) (#2493)
- Update the culdafeedback listserv email after the change from Lyris to Simplelists by @mhk33 in [#2486](https://github.com/cul-it/blacklight-cornell/pull/2486) ([DACCESS-934](https://culibrary.atlassian.net/browse/DACCESS-934)) (#2486)
- Updated e-journal titles links to go directly to EBSCO rather than the redirected erms domain by @mhk33 in [#2487](https://github.com/cul-it/blacklight-cornell/pull/2487) ([DACCESS-933](https://culibrary.atlassian.net/browse/DACCESS-933)) (#2487)

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
