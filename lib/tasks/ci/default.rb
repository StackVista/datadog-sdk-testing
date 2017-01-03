require 'rake'

require 'ci/common'
require 'bundler'

namespace :ci do
  namespace :default do |flavor|
    task before_install: ['ci:common:before_install']

    task :coverage do
      check_env
      testable, untested = integration_tests(File.dirname(__FILE__))
      total_checks = (untested + testable).length
      unless untested.empty?
        puts "Untested checks (#{untested.length}/#{total_checks})".red
        puts '-----------------------'.red
        untested.each { |check_name| puts check_name.red }
        puts ''
      end
    end

    task install: ['ci:common:install']

    task before_script: ['ci:common:before_script']

    task lint: ['ci:common:before_script', 'ci:common:before_install', 'ci:common:install', 'rubocop'] do
      if ENV['SKIP_LINT']
        puts 'Skipping lint'.yellow
      else
        check_env
        sh %(flake8 #{ENV['SDK_HOME']})
        sh %(find #{ENV['SDK_HOME']} -name '*.py' -not\
               \\( -path '*.cache*' -or -path '*embedded*' -or -path '*venv*' -or -path '*.git*' \\)\
               | xargs -n 1 pylint --rcfile=#{ENV['SDK_HOME']}/.pylintrc)
      end
    end

    task :requirements do
      check_env
      gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
      sh "#{gem_home}/lib/tasks/ci/hooks/pre-commit.py"
    end

    task script: ['ci:common:script', :coverage, :lint] do
      check_env
      Rake::Task['ci:common:run_tests'].invoke(['default'])
    end

    task cleanup: ['ci:common:cleanup']

    task :execute do
      exception = nil
      begin
        %w(before_install install before_script
           script).each do |t|
          Rake::Task["#{flavor.scope.path}:#{t}"].invoke
        end
      rescue => e
        exception = e
        puts "Failed task: #{e.class} #{e.message}".red
      end
      if ENV['SKIP_CLEANUP']
        puts 'Skipping cleanup, disposable environments are great'.yellow
      else
        puts 'Cleaning up'
        Rake::Task["#{flavor.scope.path}:cleanup"].invoke
      end
      raise exception if exception
    end
  end
end
