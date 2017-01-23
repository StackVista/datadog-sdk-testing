# datadog-sdk-testing
Gem repo providing Integration SDK testing/scaffolding facilities.

[![Gem Version](https://badge.fury.io/rb/datadog-sdk-testing.svg)](https://badge.fury.io/rb/datadog-sdk-testing)

## usage
This gem essentially just provides a set of rake tasks to help you get up and running with integration testing and scaffolding. We expect to use this gem in `integrations-core` and `integrations-extras`.

To use the tasks in this gem just add a Rakefile to the relevant project with these contents:

```
#!/usr/bin/env rake

require 'rake'

unless ENV['CI']
  rakefile_dir = File.dirname(__FILE__)
  ENV['TRAVIS_BUILD_DIR'] = rakefile_dir
  ENV['INTEGRATIONS_DIR'] = File.join(rakefile_dir, 'embedded')
  ENV['PIP_CACHE'] = File.join(rakefile_dir, '.cache/pip')
  ENV['VOLATILE_DIR'] = '/tmp/integration-sdk-testing'
  ENV['CONCURRENCY'] = ENV['CONCURRENCY'] || '2'
  ENV['NOSE_FILTER'] = 'not windows'
  ENV['RUN_VENV'] = 'true'
  ENV['SDK_TESTING'] = 'true'
end

ENV['SDK_HOME'] = File.dirname(__FILE__)

spec = Gem::Specification.find_by_name 'datadog-sdk-testing'
load "#{spec.gem_dir}/lib/tasks/sdk.rake"
```
