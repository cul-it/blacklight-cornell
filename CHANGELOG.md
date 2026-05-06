# Changelog

## 2026-05-06 - Sprint release (dev -> main)

### 🚀 Features

- Add automated changelog generation GitHub Actions workflow with Copilot release notes, Jira linking, and draft/official modes by @ in [#2458](https://github.com/cul-it/blacklight-cornell/pull/2458) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2458)
- Add PR template to standardize pull request descriptions across the repository by @ in [#2455](https://github.com/cul-it/blacklight-cornell/pull/2455) (#2455)

### 🐛 Bug Fixes

- Resolve issue where changelog workflow now correctly reads release-note instructions from the current branch instead of main by @ in [#2466](https://github.com/cul-it/blacklight-cornell/pull/2466) (#2466)
- Resolve Devise::MissingWarden errors in controller specs by including Devise test helpers so Warden-dependent actions like initialize_bookbag_state evaluate correctly by @ in [#2465](https://github.com/cul-it/blacklight-cornell/pull/2465) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2465)
- Resolve back button breakage in bento search by removing unused legacy anchor scroll JavaScript by @ in [#2463](https://github.com/cul-it/blacklight-cornell/pull/2463) ([DACCESS-868](https://culibrary.atlassian.net/browse/DACCESS-868)) (#2463)
- Resolve issue where Book Bag item count now displays correctly on page load without requiring the user to navigate to the bookbag view first by @ in [#2462](https://github.com/cul-it/blacklight-cornell/pull/2462) ([DACCESS-840](https://culibrary.atlassian.net/browse/DACCESS-840)) (#2462)

### 🦮 Accessibility

- Update fixed font sizes to relative units in Databases, Digital Collections, Terms of Use, and Footer sections for improved accessibility compliance by @ in [#2459](https://github.com/cul-it/blacklight-cornell/pull/2459) ([DACCESS-894](https://culibrary.atlassian.net/browse/DACCESS-894)) (#2459)
- Fix aria-hidden typo in availability box, correct italic markup on database paragraphs, and replace misused H3 heading elements with divs on item view display by @ in [#2456](https://github.com/cul-it/blacklight-cornell/pull/2456) ([DACCESS-899](https://culibrary.atlassian.net/browse/DACCESS-899)) (#2456)

### 🧰 Maintenance

- Improve Copilot changelog workflow with consistent section ordering, automated changelog PR creation against dev, and branch protection compliance by @ in [#2468](https://github.com/cul-it/blacklight-cornell/pull/2468) ([DACCESS-907](https://culibrary.atlassian.net/browse/DACCESS-907)) (#2468)
- Replace deprecated document_show_fields rendering with DocumentMetadataComponent to resolve Blacklight 8 deprecation warnings and update per-field display logic by @ in [#2461](https://github.com/cul-it/blacklight-cornell/pull/2461) ([DACCESS-824](https://culibrary.atlassian.net/browse/DACCESS-824), [DACCESS-825](https://culibrary.atlassian.net/browse/DACCESS-825)) (#2461)
- Fix flaky Cucumber test for JavaScript-loaded pages by ensuring page paths are always root-relative, eliminating state-dependent navigation failures by @ in [#2457](https://github.com/cul-it/blacklight-cornell/pull/2457) ([DACCESS-644](https://culibrary.atlassian.net/browse/DACCESS-644)) (#2457)
- Upgrade application to Rails 8 with updated gem dependencies, security patches, and custom error pages for 400 and 422 responses by @ in [#2453](https://github.com/cul-it/blacklight-cornell/pull/2453) ([DACCESS-856](https://culibrary.atlassian.net/browse/DACCESS-856), [DACCESS-887](https://culibrary.atlassian.net/browse/DACCESS-887)) (#2453)
- Fix Jenkins CI pipeline to run test containers as the Jenkins user instead of root, resolving coverage file permission errors that blocked workspace cleanup by @ in [#2438](https://github.com/cul-it/blacklight-cornell/pull/2438) ([DACCESS-737](https://culibrary.atlassian.net/browse/DACCESS-737)) (#2438)

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
