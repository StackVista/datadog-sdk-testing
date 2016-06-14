#!/usr/bin/env rake
# encoding: utf-8
# 3p
require 'rake/clean'
require 'rubocop/rake_task'
require 'bundler'

# Flavored Travis CI jobs
require 'ci/default'
Rake.add_rakelib './ci/'

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
  input = ''
  print "Are you sure you want to delete the SDK environment (y/n)? "
  input = STDIN.gets.chomp
  case input.upcase
  when "Y"
    `rm -rf #{ENV['SDK_HOME']}/venv` if File.directory?("#{ENV['SDK_HOME']}/venv")
    `rm -rf #{ENV['SDK_HOME']}/embedded` if File.directory?("#{ENV['SDK_HOME']}/embedded")
    puts "virtual environment, agent source removed."
  when "N"
    puts "aborting the task..."
  end
end

desc 'Setup git hooks'
task 'setup_hooks' do
  check_env
  gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
  sh "ln -sf #{gem_home}/lib/tasks/ci/hooks/pre-commit.py #{ENV['SDK_HOME']}}/.git/hooks/pre-commit"
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
    puts "generating skeleton files for #{args[:option]}"
    gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
    capitalized = args[:option].capitalize
    sh "mkdir -p #{ENV['SDK_HOME']}/ci"
    sh "mkdir -p #{ENV['SDK_HOME']}/#{args[:option]}"
    sh "cp #{gem_home}/lib/config/ci/skeleton.rake #{ENV['SDK_HOME']}/ci/#{args[:option]}.rake"
    sh "cp #{gem_home}/lib/config/manifest.json #{ENV['SDK_HOME']}/#{args[:option]}/manifest.json"
    sh "cp #{gem_home}/lib/config/check.py #{ENV['SDK_HOME']}/#{args[:option]}/check.py"
    sh "cp #{gem_home}/lib/config/test_skeleton.py #{ENV['SDK_HOME']}/#{args[:option]}/test_#{args[:option]}.py"
    sh "cp #{gem_home}/lib/config/metadata.csv #{ENV['SDK_HOME']}/#{args[:option]}/metadata.csv"
    sh "cp #{gem_home}/lib/config/requirements.txt #{ENV['SDK_HOME']}/#{args[:option]}/requirements.txt"
    sh "cp #{gem_home}/lib/config/README.md #{ENV['SDK_HOME']}/#{args[:option]}/README.md"
    sh "find #{ENV['SDK_HOME']}/#{args[:option]} -type f -exec sed -i '' \"s/skeleton/#{args[:option]}/g\" {} \\;"
    sh "find #{ENV['SDK_HOME']}/#{args[:option]} -type f -exec sed -i '' \"s/Skeleton/#{capitalized}/g\" {} \\;"
    sh "sed -i '' \"s/skeleton/#{args[:option]}/g\" #{ENV['SDK_HOME']}/ci/#{args[:option]}.rake"
    sh "sed -i '' \"s/Skeleton/#{capitalized}/g\" #{ENV['SDK_HOME']}/ci/#{args[:option]}.rake"
    sh "git add #{ENV['SDK_HOME']}/ci/#{args[:option]}.rake"
    sh "git add #{ENV['SDK_HOME']}/#{args[:option]}/*"

    new_file = "#{ENV['SDK_HOME']}/circle.yml.new"
    File.open(new_file, 'w') do |fo|
      File.foreach("#{ENV['SDK_HOME']}/circle.yml") do |line|
        fo.puts "        - rake ci:run[#{args[:option]}]" if line =~ /bundle\ exec\ rake\ requirements/
        fo.puts line
      end
    end
    File.delete("#{ENV['SDK_HOME']}/circle.yml")
    File.rename(new_file, "#{ENV['SDK_HOME']}/circle.yml")

    new_file = "#{ENV['SDK_HOME']}/.travis.yml.new"
    File.open(new_file, 'w') do |fo|
      File.foreach("#{ENV['SDK_HOME']}/.travis.yml") do |line|
        fo.puts "  - rake ci:run[#{args[:option]}]" if line =~ /bundle\ exec\ rake\ requirements/
        fo.puts line
      end
    end
    File.delete("#{ENV['SDK_HOME']}/.travis.yml")
    File.rename(new_file, "#{ENV['SDK_HOME']}/.travis.yml")
  end
end

namespace :ci do
  desc 'Run integration tests'
  task :run, [:flavor, :mocked] do |_, args|
    check_env
    puts 'Assuming you are running these tests locally' unless ENV['TRAVIS']
    flavor = args[:flavor] || ENV['TRAVIS_FLAVOR'] || 'default'
    mocked = args[:mocked] || false
    flavors = flavor.split(',')
    flavors.each do |f|
      Rake::Task["ci:#{f}:execute"].invoke(mocked)
    end
  end

  desc 'Run mock tests'
  task :run_mocks, [:flavor] do |_, args|
    check_env
    Rake::Task["ci:run"].invoke(args[:flavor], true)
  end
end

task default: ['lint', 'ci:run']
