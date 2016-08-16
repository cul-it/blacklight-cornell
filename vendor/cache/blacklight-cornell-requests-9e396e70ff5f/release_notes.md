# Release Notes - blacklight-cornell-requests

## v1.3

- Updated to work with Blacklight 6 (now requires Blacklight 5.9 or higher)

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