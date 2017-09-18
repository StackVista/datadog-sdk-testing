require 'colorize'
require 'httparty'
require 'socket'
require 'time'
require 'timeout'
require 'securerandom'

# Colors don't work on Appveyor
String.disable_colorization = true if Gem.win_platform?

def check_env
  abort 'SDK_HOME env variable must be defined in your Rakefile to used this gem.' unless ENV['SDK_HOME']
end

def bin_in_path?(binary)
  ENV['PATH'].split(':').collect { |d| Dir.entries d if Dir.exist? d }.flatten.include? binary
end

def in_ci_env
  ENV['TRAVIS'] || ENV['CIRCLECI']
end

def travis_circle_env
  abort 'You are not in a Travis/Circle CI environment, this task wont apply.' unless in_ci_env
end

def sed(source, op, a, b, mods)
  cmd = "#{op}/#{a}"
  cmd = "#{cmd}/#{b}" unless b.nil? || b.empty?
  sh "sed -i '' \"#{cmd}/#{mods}\" #{source} || sed -i \"#{cmd}/#{mods}\" #{source}"
end

def sleep_for(secs)
  puts "Sleeping for #{secs}s".blue
  sleep(secs)
end

def wait_on_docker_logs(c_name, max_wait, *include_array)
  count = 0
  logs = `docker logs #{c_name} 2>&1`
  puts "Waiting for #{c_name} to come up"

  until count == max_wait || include_array.any? { |phrase| logs.include?(phrase) }
    sleep(1)
    logs = `docker logs #{c_name} 2>&1`
    count += 1
  end

  if include_array.any? { |phrase| logs.include?(phrase) }
    puts "#{c_name} is up!"
  else
    sh %(docker logs #{c_name} 2>&1)
    raise
  end
end

def section(name)
  timestamp = Time.now.utc.iso8601
  puts ''
  puts "[#{timestamp}] >>>>>>>>>>>>>> #{name} STAGE".black.on_white
  puts ''
end

def in_venv
  ENV['RUN_VENV'] && ENV['RUN_VENV'] == 'true' ? true : false
end

def install_requirements(req_file, pip_options = nil, output = nil, use_venv = nil)
  pip_command = use_venv ? "#{ENV['SDK_HOME']}/venv/bin/pip" : 'pip'
  redirect_output = output ? "2>&1 >> #{output}" : ''
  pip_options = '' if pip_options.nil?
  sh "#{pip_command} install -r #{req_file} #{pip_options} #{redirect_output}"
end

def test_files(sdk_dir)
  Dir.glob(File.join(sdk_dir, '**/test_*.py')).reject do |path|
    !%r{#{sdk_dir}/embedded/.*$}.match(path).nil? || !%r{#{sdk_dir}\/venv\/.*$}.match(path).nil?
  end
end

def integration_tests(root_dir)
  sdk_dir = ENV['SDK_HOME'] || root_dir
  integrations = []
  untested = []
  testable = []
  test_files(sdk_dir).each do |check|
    integration_name = /test_((\w|_)+).py$/.match(check)[1]
    integrations.push(integration_name)
    if Dir.exist?(File.join(sdk_dir, integration_name))
      testable.push(check)
    else
      untested.push(check)
    end
  end
  [testable, untested]
end

def move_file(src, dst)
  File.delete(dst)
  File.rename(src, dst)
end

def check_travis_flavor(flavor, version = nil)
  version = 'latest' if version.nil?
  File.foreach("#{ENV['SDK_HOME']}/.travis.yml") do |line|
    return false if line =~ /- TRAVIS_FLAVOR=#{flavor} FLAVOR_VERSION=#{version}/
  end
  true
end

def add_travis_flavor(flavor, version = nil)
  new_file = "#{ENV['SDK_HOME']}/.travis.yml.new"
  version = 'latest' if version.nil?
  added = false
  File.open(new_file, 'w') do |fo|
    File.foreach("#{ENV['SDK_HOME']}/.travis.yml") do |line|
      if !added && line =~ /# END OF TRAVIS MATRIX|- TRAVIS_FLAVOR=#{flavor}/
        fo.puts "    - TRAVIS_FLAVOR=#{flavor} FLAVOR_VERSION=#{version}"
        added = true
      end
      fo.puts line
    end
  end
  move_file(new_file, "#{ENV['SDK_HOME']}/.travis.yml")
end

def add_circleci_flavor(flavor)
  new_file = "#{ENV['SDK_HOME']}/circle.yml.new"
  File.open(new_file, 'w') do |fo|
    File.foreach("#{ENV['SDK_HOME']}/circle.yml") do |line|
      fo.puts "        - rake ci:run[#{flavor}]" if line =~ /bundle\ exec\ rake\ requirements/
      fo.puts line
    end
  end
  move_file(new_file, "#{ENV['SDK_HOME']}/circle.yml")
end

def copy_skeleton(source, dst, integration)
  gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
  sh "cp #{gem_home}/#{source} #{ENV['SDK_HOME']}/#{integration}/#{dst}"
end

def create_integration_path(integration)
  sh "mkdir -p #{ENV['SDK_HOME']}/#{integration}/ci"
end

def rename_skeleton(integration)
  capitalized = integration.capitalize
  Dir.glob("#{ENV['SDK_HOME']}/#{integration}/**/*") do |f|
    if File.file?(f)
      sed(f, 's', 'skeleton', integration.to_s, 'g')
      sed(f, 's', 'Skeleton', capitalized.to_s, 'g')
    end
  end
end

def replace_guid(integration)
  guid = SecureRandom.uuid
  f = "#{ENV['SDK_HOME']}/#{integration}/manifest.json"
  sed(f, 's', 'guid_replaceme', guid.to_s, 'g')
end

def generate_skeleton(integration)
  copy_skeleton('lib/config/ci/skeleton.rake', "ci/#{integration}.rake", integration)
  copy_skeleton('lib/config/manifest.json', 'manifest.json', integration)
  copy_skeleton('lib/config/check.py', 'check.py', integration)
  copy_skeleton('lib/config/test_skeleton.py', "test_#{integration}.py", integration)
  copy_skeleton('lib/config/metadata.csv', 'metadata.csv', integration)
  copy_skeleton('lib/config/requirements.txt', 'requirements.txt', integration)
  copy_skeleton('lib/config/README.md', 'README.md', integration)
  copy_skeleton('lib/config/CHANGELOG.md', 'CHANGELOG.md', integration)
  copy_skeleton('lib/config/conf.yaml.example', 'conf.yaml.example', integration)
end

def create_skeleton(integration)
  if File.directory?("#{ENV['SDK_HOME']}/#{integration}")
    puts "directory already exists for #{integration} - bailing out."
    return
  end

  puts "generating skeleton files for #{integration}"
  create_integration_path(integration.to_s)
  generate_skeleton(integration.to_s)
  rename_skeleton(integration.to_s)

  replace_guid(integration.to_s)

  add_travis_flavor(integration)
  add_circleci_flavor(integration)
end

# helper class to wait for TCP/HTTP services to boot
class Wait
  DEFAULT_TIMEOUT = 10

  def self.check_port(port)
    Timeout.timeout(0.5) do
      begin
        s = TCPSocket.new('localhost', port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, EOFError, Errno::ECONNRESET
        return false
      end
    end
  rescue Timeout::Error
    return false
  end

  def self.check_url(url)
    Timeout.timeout(0.5) do
      begin
        r = HTTParty.get(url)
        return (200...300).cover? r.code
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, EOFError, Errno::ECONNRESET
        return false
      end
    end
  rescue Timeout::Error
    return false
  end

  def self.check_file(file_path)
    File.exist?(file_path)
  end

  def self.check(smth)
    if smth.is_a? Integer
      check_port smth
    elsif smth.include? 'http'
      check_url smth
    else
      check_file smth
    end
  end

  def self.for(smth, max_timeout = DEFAULT_TIMEOUT)
    start_time = Time.now
    status = false
    n = 1
    puts "Trying #{smth}"
    loop do
      puts n.to_s
      status = check(smth)
      break if status || Time.now > start_time + max_timeout
      n += 1
      sleep 0.25
    end
    raise "Still not up after #{max_timeout}s" unless status
    puts 'Found!'
    status
  end
end

def travis_pr?
  !ENV['TRAVIS'].nil? && ENV['TRAVIS_EVENT_TYPE'] == 'pull_request'
end

def can_skip?
  return false, [] unless travis_pr?

  modified_checks = []
  puts "Comparing #{ENV['TRAVIS_PULL_REQUEST_SHA']} with #{ENV['TRAVIS_BRANCH']}"
  git_output = `git diff --name-only #{ENV['TRAVIS_BRANCH']}...#{ENV['TRAVIS_PULL_REQUEST_SHA']}`
  puts "Git diff: \n#{git_output}"
  git_output.each_line do |filename|
    filename.strip!
    puts filename
    return false, [] if filename.split('/').length < 2

    check_name = filename.split('/')[0]
    modified_checks << check_name unless modified_checks.include? check_name
  end
  [true, modified_checks]
end

namespace :ci do
  namespace :common do
    task :before_install do |t|
      section('BEFORE_INSTALL')
      # We use tempdir on Windows, no need to create it
      sh %(mkdir -p #{ENV['VOLATILE_DIR']}) unless Gem.win_platform?
      t.reenable
    end

    task :install, [:flavor] do |t, attr|
      section('INSTALL')

      flavor = attr[:flavor]
      use_venv = in_venv
      pip_command = use_venv ? 'venv/bin/pip' : 'pip'
      sdk_dir = ENV['SDK_HOME'] || Dir.pwd

      sh %(#{'python -m ' if Gem.win_platform?}#{pip_command} install --upgrade pip setuptools)
      install_requirements('requirements-test.txt',
                           "--cache-dir #{ENV['PIP_CACHE']}",
                           "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)

      flavor_file = "#{flavor}/requirements.txt"
      reqs = if flavor && File.exist?(flavor_file)
               [flavor_file]
             else
               Dir.glob(File.join(sdk_dir, '**/requirements.txt')).reject do |path|
                 !%r{#{sdk_dir}/embedded/.*$}.match(path).nil? || !%r{#{sdk_dir}\/venv\/.*$}.match(path).nil?
               end
             end

      reqs.each do |req|
        install_requirements(req,
                             "--cache-dir #{ENV['PIP_CACHE']}",
                             "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)
      end

      t.reenable
    end

    task :before_script do |t|
      section('BEFORE_SCRIPT')
      t.reenable
    end

    task :script do |t|
      section('SCRIPT')
      t.reenable
    end

    task :before_cache do |t|
      section('BEFORE_CACHE')
      t.reenable
    end

    task :cleanup do |t|
      section('CLEANUP')
      t.reenable
    end

    task :run_tests, [:flavor] do |t, attr|
      flavors = attr[:flavor]
      sdkhome = ENV['SDK_HOME'] || Dir.pwd
      filter = ENV['NOSE_FILTER'] || '1'

      nose_command = in_venv ? 'venv/bin/nosetests' : 'nosetests'
      nose = if flavors.include?('default')
               "(not requires) and #{filter}"
             else
               "(requires in ['#{flavors.join("','")}']) and #{filter}"
             end

      tests_directory, = integration_tests(sdkhome)
      flavors_group = flavors.join('|')
      unless flavors.include?('default')
        tests_directory = tests_directory.reject do |test|
          %r{.*/(#{flavors_group})/.*$}.match(test).nil?
        end
      end
      # Rake on Windows doesn't support setting the var at the beginning of the
      # command
      path = ''
      unless Gem.win_platform?
        # FIXME: make the other filters than param configurable
        # For integrations that cannot be easily installed in a
        # separate dir we symlink stuff in the rootdir
        path = %(PATH="#{ENV['INTEGRATIONS_DIR']}/bin:#{ENV['PATH']}" )
      end
      tests_directory.each do |testdir|
        sh %(#{path}#{nose_command} -s -v -A "#{nose}" #{testdir})
      end
      t.reenable
    end
  end
end
