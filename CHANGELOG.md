# CHANGELOG

0.2.2/ 2016.07.28
==================

### Changes

* [bugfix] Ensure requirements are installed for `default` test as well.

0.2.1/ 2016.07.25
==================

### Changes

* [bugfix] Fixing test launcher so that it now knows how to find nose tests (regression in 0.2.0).

0.2.0/ 2016.07.25
==================

### Changes

* [improvement] Keeping `ci/` Rakefile in SDK integration package folder. Not the SDK integrations root folder.
* [bugfix] wrap sed in function to allow compatibility with GNU and BSD seds.
* [bugfix] fallback to SDK_HOME environment variable if attribute not define on `run_tests` task.

0.1.0/ 2016.06.16
==================

### Changes

* Initial release
