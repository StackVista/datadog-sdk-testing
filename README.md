# datadog-sdk-testing
Gem repo providing Integration SDK testing/scaffolding facilities (unpublished).

## usage
This gem essentially just provides a set of rake tasks to help you get up and running with integration testing and scaffolding. We expect to use this gem in `integrations-core` and `integrations-extras`.

To use the tasks in this gem just add a Rakefile to the relevant project with these contents:

```
#!/usr/bin/env rake

require 'rake'

spec = Gem::Specification.find_by_name 'datadog-sdk-testing'
load "#{spec.gem_dir}/lib/tasks/sdk.rake"
```
