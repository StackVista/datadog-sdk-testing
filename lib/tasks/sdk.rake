#!/usr/bin/env rake
# encoding: utf-8
# 3p
require 'rake/clean'
require 'rubocop/rake_task'
require 'bundler'

# Flavored Travis CI jobs
require 'ci/default'

Dir.glob("#{ENV['SDK_HOME']}/*/ci/").each do |f|
  Rake.add_rakelib f
end

CLOBBER.include '**/*.pyc'

desc 'Setup a development environment for the SDK'
task 'setup_env' do
  check_env
  `mkdir -p #{ENV['SDK_HOME']}/venv`
  `wget -q -O #{ENV['SDK_HOME']}/venv/virtualenv.py https://raw.github.com/pypa/virtualenv/1.11.6/virtualenv.py`
  `python #{ENV['SDK_HOME']}/venv/virtualenv.py  --no-site-packages --no-pip --no-setuptools #{ENV['SDK_HOME']}/venv/`
  `wget -q -O #{ENV['SDK_HOME']}/venv/ez_setup.py https://bootstrap.pypa.io/ez_setup.py`
  `#{ENV['SDK_HOME']}/venv/bin/python #{ENV['SDK_HOME']}/venv/ez_setup.py`
  `wget -q -O #{ENV['SDK_HOME']}/venv/get-pip.py https://bootstrap.pypa.io/get-pip.py`
  `#{ENV['SDK_HOME']}/venv/bin/python #{ENV['SDK_HOME']}/venv/get-pip.py`
  # these files should be part of the SDK repos (integrations-{core, extra}
  `venv/bin/pip install -r #{ENV['SDK_HOME']}/requirements.txt` if File.exist?('requirements.txt')
  `venv/bin/pip install -r #{ENV['SDK_HOME']}/requirements-test.txt` if File.exist?('requirements-test.txt')
  # These deps are not really needed, so we ignore failures
  ENV['PIP_COMMAND'] = "#{ENV['SDK_HOME']}/venv/bin/pip"
  `git clone https://github.com/DataDog/dd-agent.git #{ENV['SDK_HOME']}/embedded/dd-agent`
  # install agent core dependencies
  `#{ENV['SDK_HOME']}/venv/bin/pip install -r #{ENV['SDK_HOME']}/embedded/dd-agent/requirements.txt`
  `echo "#{ENV['SDK_HOME']}/embedded/dd-agent/" > #{ENV['SDK_HOME']}/venv/lib/python2.7/site-packages/datadog-agent.pth`
end

desc 'Clean development environment for the SDK (remove!)'
task 'clean_env' do
  check_env
  print 'Are you sure you want to delete the SDK environment (y/n)? '
  input = STDIN.gets.chomp
  case input.upcase
  when 'Y'
    `rm -rf #{ENV['SDK_HOME']}/venv` if File.directory?("#{ENV['SDK_HOME']}/venv")
    `rm -rf #{ENV['SDK_HOME']}/embedded` if File.directory?("#{ENV['SDK_HOME']}/embedded")
    puts 'virtual environment, agent source removed.'
  when 'N'
    puts 'aborting the task...'
  end
end

desc 'Setup git hooks'
task 'setup_hooks' do
  check_env
  gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
  sh "ln -sf #{gem_home}/lib/tasks/ci/hooks/pre-commit.py #{ENV['SDK_HOME']}/.git/hooks/pre-commit"
end

desc 'Pull latest agent code'
task 'pull_latest_agent' do
  check_env
  `cd #{ENV['SDK_HOME']}/embedded/dd-agent && git fetch -p && git pull && cd -`
end

namespace :test do
  desc 'cProfile tests, then run pstats'
  task 'profile:pstats' => ['test:profile'] do
    check_env
    sh 'python -m pstats stats.dat'
  end

  desc 'Display test coverage for checks'
  task 'coverage' => 'ci:default:coverage'
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.patterns = ['ci/**/*.rb', 'Gemfile', 'Rakefile']
end

desc 'Lint the code through pylint'
task 'lint' => ['ci:default:lint'] do
end

desc 'Find requirements conflicts'
task 'requirements' => ['ci:default:requirements'] do
end

namespace :generate do
  desc 'Setup a development environment for the SDK'
  task :skeleton, :option do |_, args|
    check_env
    create_skeleton(args[:option])
  end

  desc 'Add a new integration flavor to Travis - option may be option or option,version'
  task :travis_flavor, [:option] do |_, args|
    check_env

    integration = args[:option]
    flavor = 'latest'
    flavor = args.extras[0] if args.extras.count == 1
    puts "Adding integration flavor to travis: #{integration}:#{flavor}"
    if check_travis_flavor(integration, flavor)
      add_travis_flavor(integration, flavor)
    else
      puts "#{integration}:#{flavor} already set in travis... skipping."
    end
  end
end

namespace :ci do
  desc 'Run integration tests'
  task :run, [:flavor] do |_, args|
    check_env
    puts 'Assuming you are running these tests locally' unless ENV['TRAVIS']
    flavor = args[:flavor] || ENV['TRAVIS_FLAVOR'] || 'default'
    flavors = flavor.split(',')
    flavors.each do |f|
      Rake::Task["ci:#{f}:execute"].invoke
    end
  end
end

task default: ['lint', 'ci:run']
