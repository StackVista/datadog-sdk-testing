#!/usr/bin/env rake
# encoding: utf-8

# 3p
require 'rake/clean'
require 'rubocop/rake_task'
require 'bundler'
require 'English'

# Flavored Travis CI jobs
require 'ci/default'

Dir.glob("#{ENV['SDK_HOME']}/*/ci/").each do |f|
  Rake.add_rakelib f
end

CLOBBER.include '**/*.pyc'

desc 'Setup a development environment for the SDK'
task 'setup_env' do
  check_env
  raise 'python2.7 is a requirement (python2 symlink too) - cant setup the env' unless bin_in_path?('python2')
  `mkdir -p #{ENV['SDK_HOME']}/venv`
  `wget -q -O #{ENV['SDK_HOME']}/venv/virtualenv.py https://raw.github.com/pypa/virtualenv/1.11.6/virtualenv.py`
  `python #{ENV['SDK_HOME']}/venv/virtualenv.py -p python2 --no-site-packages --no-pip --no-setuptools #{ENV['SDK_HOME']}/venv/`
  `wget -q -O #{ENV['SDK_HOME']}/venv/ez_setup.py https://bootstrap.pypa.io/ez_setup.py`
  `#{ENV['SDK_HOME']}/venv/bin/python #{ENV['SDK_HOME']}/venv/ez_setup.py`
  `wget -q -O #{ENV['SDK_HOME']}/venv/get-pip.py https://bootstrap.pypa.io/get-pip.py`
  `#{ENV['SDK_HOME']}/venv/bin/python #{ENV['SDK_HOME']}/venv/get-pip.py`
  # these files should be part of the SDK repos (integrations-{core, extra}
  `venv/bin/pip install -r #{ENV['SDK_HOME']}/requirements-test.txt` if File.exist?('requirements-test.txt')
  # These deps are not really needed, so we ignore failures
  ENV['PIP_COMMAND'] = "#{ENV['SDK_HOME']}/venv/bin/pip"
  `git clone --depth 1 https://github.com/DataDog/dd-agent.git #{ENV['SDK_HOME']}/embedded/dd-agent`
  # install agent core dependencies
  `#{ENV['SDK_HOME']}/venv/bin/pip install -r #{ENV['SDK_HOME']}/embedded/dd-agent/requirements.txt`
  `echo "#{ENV['SDK_HOME']}/embedded/dd-agent/" > #{ENV['SDK_HOME']}/venv/lib/python2.7/site-packages/datadog-agent.pth`
  gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
  `cp #{gem_home}/lib/config/datadog.conf #{ENV['SDK_HOME']}/embedded/dd-agent/datadog.conf`
  # This sometimes causes check setup to fail
  FileUtils.rm Dir.glob('setuptools*.zip')
end

desc 'Grab latest external dd-agent libraries'
task 'setup_agent_libs' do
  check_env
  agent_dir = in_ci_env ? "#{ENV['HOME']}/dd-agent/" : "#{ENV['SDK_HOME']}/embedded/dd-agent/"

  Dir.chdir(agent_dir) do
    `bundle install`
    `bundle exec rake -T | grep setup_libs > /dev/null 2>&1`
    raise "Rake task 'setup_libs' not found!" if $CHILD_STATUS.exitstatus != 0
    # Use `sh` so we don't ingest standard output and error
    sh 'bundle exec rake setup_libs'
  end
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

desc 'Wipe integration'
task 'wipe', :option do |_, args|
  flavor = args[:option] || false
  abort 'please specify an integration to remove' unless flavor
  check_env
  print "Are you sure you want to remove the #{flavor} integration (y/n)? "
  input = STDIN.gets.chomp
  case input.upcase
  when 'Y'
    `rm -rf #{ENV['SDK_HOME']}/#{flavor}` if File.directory?("#{ENV['SDK_HOME']}/#{flavor}")
    `rm -rf #{ENV['SDK_HOME']}/ci/#{flavor}.rake` if File.exist?("#{ENV['SDK_HOME']}/ci/#{flavor}.rake")
    puts 'source and CI files.'
    # two searches on travis.yml because of BSD sed.
    sed("#{ENV['SDK_HOME']}/.travis.yml", '', "=#{flavor}\\ ", '', 'd')
    sed("#{ENV['SDK_HOME']}/.travis.yml", '', "=#{flavor}$", '', 'd')
    sed("#{ENV['SDK_HOME']}/circle.yml", '', "\\[#{flavor}\\]", '', 'd')
    puts "Please run 'git rm -r #{flavor}' to complete the wipe."
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

desc 'Prepare Travis/Circle CI'
task 'prep_travis_ci' do
  check_env
  travis_circle_env
  gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
  sh "ln -sf #{gem_home}/lib/config/datadog.conf ~/dd-agent/datadog.conf"
end

desc 'Pull latest agent code'
task 'pull_latest_agent' do
  check_env
  `cd #{ENV['SDK_HOME']}/embedded/dd-agent && git fetch -p && git pull --depth 1 && cd -`
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
  t.patterns = ['./*/ci/*.rake', 'Gemfile', 'Rakefile']
end

desc 'Lint the code through pylint'
task 'lint' => ['ci:default:lint'] do
end

desc 'Find requirements conflicts'
task 'requirements' => ['ci:default:requirements'] do
end

desc 'Check that requirements files are properly structured'
task 'requirements_file' => ['ci:default:requirements_file'] do
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
    can_skip, checks = can_skip?
    can_skip &&= !%w[default].include?(flavor)

    flavors = flavor.split(',')
    flavors.each do |f|
      if can_skip && !checks.include?(flavor)
        puts "skipping #{flavor} tests, not affected by the change".yellow
        next
      end
      Rake::Task["ci:#{f}:execute"].invoke
    end
  end
end

task default: ['lint', 'requirements_file', 'ci:run']
