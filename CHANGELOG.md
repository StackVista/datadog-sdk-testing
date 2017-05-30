# CHANGELOG

0.7.1/ 2017.05.30
=================

### Changes

* [bugfix] english should be English in case-sensitive FS's.

0.7.0/ 2017.05.30
=================

### Changes

* [feature] Add helpers to dev/CI environments to grab libs. See [#60][]
* [bugfix] Checks if a requirements ends with a new line. See [#59][]

0.6.1/ 2017.03.30
=================

### Changes

* [bugfix] re-add INSTALL section. See [#57][]
* [other] do not install integrations-* requirements.txt. See [#57][]

0.6.0/ 2017.03.30
=================

### Changes

* [improvement] Clean setuptools remain after setup\_env. See [#48][].
* [improvement] Handle GNU sed on Mac. See [#50][].
* [improvement] Add an option in the skeleton to skip tests. See [#51][].
* [improvement] Faster requirements install. See [#54][].
* [improvement] Faster requirements install in the skeleton. See [#55][].
* [improvement] Declare the gem dependencies in the gemspec. See [#56][].
* [other] Do not call git for the user. See [#50][].
* [other] Do not suggest using the constructor in the skeleton. See [#52][].

0.5.1/ 2017.02.14
==================

### Changes

* [improvement] Better detect comments, and unpinned version. See [#47][].
* [improvement] Add pattern definition via environment variable. See [#47][].
* [bugfix] Fix bad reporting of mismatch locations. See [#47][].

0.5.0/ 2017.02.13
==================

### Changes

* [feature] Skip CI for check if unchanged. See [#44][].
* [feature] Revamp of requirements tool/hook. See [#45][].
* [bugfix] Add changelog to integration skeleton. See [#46][].

0.4.9/ 2017.02.03
==================

### Changes

* [bugfix] GUID replacement fails on sed. See [#42][] (Thanks [@ksauzz][]).

0.4.8/ 2017.02.03
==================

### Changes

* [bugfix] fix OSX regression with xargs. See [#41][].

0.4.7/ 2017.01.30
==================

### Changes

* [bugfix] fix regression + don't attempt to lint if nothing there. See [#40][].

0.4.6/ 2017.01.30
==================

### Changes

* [bugfix] Include GUID in manifest - necessary for windows. See [#38][].
* [bugfix] CircleCI - gnore ruby vendor directory when linting. See [#39][].

0.4.5/ 2017.01.27
==================

### Changes

* [bugfix] Updating manifest template to account for supported OSs. See [#37][].

0.4.4/ 2017.01.23
==================

### Changes

* [bugfix] Remove auto execution of tasks in `common.rb`. See [#32][].
* [bugfix] Use python2 to create the venv. See [#36][] (thanks [@lastmikoi][]).
* [bugfix] Fix patterns of rubocoped files. See [#35][].

0.4.3/ 2017.01.13
==================

### Changes

* [bugfix] Improve linting speeds. See [#34][].

0.4.2/ 2017.01.04
==================

### Changes

* [bugfix] Fix broken test filtering logic. See [#31][].

0.4.1/ 2017.01.03
==================

### Changes

* [bugfix] adding forgotten SKIP_LINT env var support. See [#30][].
* [bugfix] Fixing multiple rubocop issues. See [#30][].

0.4.0/ 2016.12.29
==================

### Changes

* [feature] add wipe task to remove integrations. See [#2][].
* [feature] Docker: add helper to wait for logs expression hit or raise. See [#29][].

0.3.5/ 2016.12.22
==================

### Changes

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

<!--- The following link definition list is generated by PimpMyChangelog --->
[#2]: https://github.com/DataDog/datadog-sdk-testing/issues/2
[#29]: https://github.com/DataDog/datadog-sdk-testing/issues/29
[#30]: https://github.com/DataDog/datadog-sdk-testing/issues/30
[#31]: https://github.com/DataDog/datadog-sdk-testing/issues/31
[#32]: https://github.com/DataDog/datadog-sdk-testing/issues/32
[#34]: https://github.com/DataDog/datadog-sdk-testing/issues/34
[#35]: https://github.com/DataDog/datadog-sdk-testing/issues/35
[#36]: https://github.com/DataDog/datadog-sdk-testing/issues/36
[#37]: https://github.com/DataDog/datadog-sdk-testing/issues/37
[#38]: https://github.com/DataDog/datadog-sdk-testing/issues/38
[#39]: https://github.com/DataDog/datadog-sdk-testing/issues/39
[#40]: https://github.com/DataDog/datadog-sdk-testing/issues/40
[#41]: https://github.com/DataDog/datadog-sdk-testing/issues/41
[#42]: https://github.com/DataDog/datadog-sdk-testing/issues/42
[#44]: https://github.com/DataDog/datadog-sdk-testing/issues/44
[#45]: https://github.com/DataDog/datadog-sdk-testing/issues/45
[#46]: https://github.com/DataDog/datadog-sdk-testing/issues/46
[#47]: https://github.com/DataDog/datadog-sdk-testing/issues/47
[#48]: https://github.com/DataDog/datadog-sdk-testing/issues/48
[#50]: https://github.com/DataDog/datadog-sdk-testing/issues/50
[#51]: https://github.com/DataDog/datadog-sdk-testing/issues/51
[#52]: https://github.com/DataDog/datadog-sdk-testing/issues/52
[#54]: https://github.com/DataDog/datadog-sdk-testing/issues/54
[#55]: https://github.com/DataDog/datadog-sdk-testing/issues/55
[#56]: https://github.com/DataDog/datadog-sdk-testing/issues/56
[#57]: https://github.com/DataDog/datadog-sdk-testing/issues/57
[#59]: https://github.com/DataDog/datadog-sdk-testing/issues/59
[#60]: https://github.com/DataDog/datadog-sdk-testing/issues/60
[@ksauzz]: https://github.com/ksauzz
[@lastmikoi]: https://github.com/lastmikoi
