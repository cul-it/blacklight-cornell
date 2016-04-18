# Release Notes - blacklight-cornell-requests

## v1.2.2

### Enhancements
- Cleaned up markup in request forms
- Updated tests
- Added item location to copy selection view (DISCOVERYACCESS-2278)

### Bug fixes
- Users no longer get stuck in a loop when trying to request different volumes from a single record (DISCOVERYACCESS-2438)


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
