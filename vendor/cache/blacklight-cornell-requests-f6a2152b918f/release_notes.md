# Release Notes - blacklight-cornell-requests

## v1.4.0

### New features
- Adds support for faculty office delivery and special program delivery options using data from the external CUL "Special Delivery" web service (DISCOVERYACCESS-2445, #49)

### Enhancements
- Adds "loading" spinners to volume selection controls to indicate progress during long page load times (DISCOVERYACCESS-2983, #87)
- Volumes in selection list now indicate if they are on reserve or non-circulating (DISCOVERYACCESS-747, #33)

### Bug fixes

## v1.3.2
- Fixed a bug that caused a recall request to loop back to the volume selection screen (DISCOVERYACCESS-2471)

## v1.3.1

### Enhancements
- "Document Delivery" labels changed to "ScanIt" (DISCOVERYACCESS-2705)
- Delivery methods can now be individually disabled by using the ENV file configuration (#80)

### Bug fixes
- Fixed a TypeError bug (DISCOVERYACCESS-2766)
- Fix bug where a single multivol_b item (a bound-with) goes into an endless loop upon request (#74)

## v1.3
- Engine updated for compatibility with Blacklight 6
- Fixed a bug that prevented reserve items from being requested through BD

## v1.2.7
- Fixed a bug preventing reserve items from being requested through Borrow Direct

## v1.2.6
- Added a check for empty circ_policy_locs database table with AppSignal integration

## v1.2.5

### Bug fixes
- Fixed a bug that caused a fatal error if no request options were available for an item
- Fixed a bug in the circ policy database query
- Fixed a bug that made books and recordings at Music unrequestable

## v1.2.4

### Enhancements
- Greatly improved request page load time (DISCOVERYACCESS-2684)
- Added ILL link to volume select screen (DISCOVERYACCESS-2703)
- Restored volume selection via URL parameters (GH #62)
- Document Delivery now appears as an option for periodicals and all Annex items (DISCOVERYACCESS-1257) - Added support for item type 39 ('unbound') (DISCOVERYACCESS-1085 ; GH #36)

### Bug fixes
- Ensured that invalid pickup locations wouldn't appear as options in the location select list ( DISCOVERYACCESS-2682)
- Removed hold option for records without any item records (e.g., current newspapers) (DISCOVERYACCESS-1477)
- Voyager requests (L2L, hold, recall) are now excluded for items at the Music library (DISCOVERYACCESS-1381)

## v1.2.3

### Bug fixes
- RMC items no longer appear in the volume selection list

## v1.2.2

### Enhancements
- Cleaned up markup in request forms
- Updated tests
- Added item location to copy selection view (DISCOVERYACCESS-2278)

### Bug fixes


## v1.2.1
- Improved parsing of ISBNs for Borrow Direct searches

## v1.2

### Enhancements
- Borrow Direct settings have been updated to work with the new BD production database (DISCOVERYACCESS-2006)
- Added an option to route exception notifications (mostly for Borrow Direct) to HipChat

### Bug fixes
- Fixed the broken purchase request submit button (DISCOVERYACCESS-1790)
- Fixed a bug where request comments were not carried through to Voyager (DISCOVERYACCESS-2084)

## v1.1.4

### Bug fixes
- Added Borrow Direct API key and updated to latest version of borrow_direct gem to fix broken BD calling
