Gem::Specification.new do |s|
  s.name          = 'datadog-sdk-testing'
  s.version       = '0.6.1'
  s.summary       = 'Datadog Integration SDK testing/scaffolding facilities.'
  s.description   = 'Datadog Integration SDK testing/scaffolding gem'
  s.authors       = ['Jaime Fullaondo']
  s.email         = 'jaime.fullaondo@datadoghq.com'
  s.require_paths = ['lib/tasks/']
  s.files         = ['lib/tasks/sdk.rake',
                     'lib/tasks/ci/default.rb',
                     'lib/tasks/ci/common.rb',
                     'lib/tasks/ci/hooks/pre-commit.py',
                     'lib/config/check.py',
                     'lib/config/ci/skeleton.rake',
                     'lib/config/conf.yaml.example',
                     'lib/config/manifest.json',
                     'lib/config/datadog.conf',
                     'lib/config/metadata.csv',
                     'lib/config/README.md',
                     'lib/config/CHANGELOG.md',
                     'lib/config/requirements.txt',
                     'lib/config/test_skeleton.py',
                     'README.md',
                     'LICENSE']
  s.homepage      = 'http://rubygems.org/gems/datadog-sdk-testing'
  s.license       = 'MIT'
  s.add_runtime_dependency 'colorize', '~> 0.8'
  s.add_runtime_dependency 'httparty', '~> 0.14'
  s.add_runtime_dependency 'rake', '~> 11.0'
  s.add_runtime_dependency 'rubocop', '~> 0.38'
end
