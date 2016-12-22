# CHANGELOG

0.3.5/ 2016.12.22
==================

### changes

* [bugfix] use better env vars to detect ci environment.

0.3.4/ 2016.12.22
==================

### Changes

* [improvement] adds a small task to prepare Travis/Circle CI environments.

0.3.3/ 2016.11.18
==================

### Changes

* [bugfix] fixes bug in SDK setup_env task.

0.3.2/ 2016.11.14
==================

### Changes

* [bugfix] adds datadog.conf file to agent directory.
* [bugfix] EOFile will no longer be a fatal error for wait.
* [bugfix] Fixing broken guard statements.

* [ci] Rubocop max block length is now 90, instead of 25.

0.3.1/ 2016.09.15
==================

### Changes

* [bugfix] `manifest.json` was getting copied with bad name - comma should be dot.
* [bugfix] sample config YAML should be copied to integration skeleton.

0.3.0/ 2016.08.22
==================

### Changes

* [improvement] New Task to allow adding new flavor to existing integration.
* [improvement] Enable Matrix (flavored) testing on TravisCI.

* [bugfix] big refactor to be rubocop compliant.

* [ci] enabled rubocop linting.

0.2.6/ 2016.08.08
==================

### Changes

* [improvement] Removing separate mock test facilities, all tests will be run together.

0.2.5/ 2016.08.03
==================

### Changes

* [bugfix] The [lint] task may also install requirements, ensure the volatile dir exists.

0.2.4/ 2016.08.01
==================

### Changes

* [bugfix] When the [default] task runs, ensure the volatile dir exists.
* [improvement] Metadata csv should have a descriptive header for each field.

0.2.3/ 2016.07.29
==================

### Changes

* [bugfix] Reqs required before lint task, make sure they're satisfied.
* [bugfix] Do not allow overwriting if integration already exists with same name.
* [bugfix] Fix hook setup task - remove extra `}`.

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
