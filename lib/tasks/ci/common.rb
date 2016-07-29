require 'colorize'
require 'httparty'
require 'socket'
require 'time'
require 'timeout'

# Colors don't work on Appveyor
String.disable_colorization = true if Gem.win_platform?


def check_env
  abort 'SDK_HOME env variable must be defined in your Rakefile to used this gem.' unless ENV['SDK_HOME']
end

def sed(source, a, b, mods)
  if RUBY_PLATFORM.include? 'darwin'
    sh "sed -i '' \"s/#{a}/#{b}/#{mods}\" #{source}"
  else
    sh "sed -i \"s/#{a}/#{b}/#{mods}\" #{source}"
  end
end

def sleep_for(secs)
  puts "Sleeping for #{secs}s".blue
  sleep(secs)
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
  File.exist?(req_file) && File.open(req_file, 'r') do |f|
    f.each_line do |line|
      line.strip!
      unless line.empty? || line.start_with?('#')
        sh %(#{pip_command} install #{line} #{pip_options} #{redirect_output}\
             || echo 'Unable to install #{line}' #{redirect_output})
      end
    end
  end
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

# helper class to wait for TCP/HTTP services to boot
class Wait
  DEFAULT_TIMEOUT = 10

  def self.check_port(port)
    Timeout.timeout(0.5) do
      begin
        s = TCPSocket.new('localhost', port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
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
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
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

namespace :ci do
  namespace :common do
    task :before_install do |t|
      section('BEFORE_INSTALL')
      # We use tempdir on Windows, no need to create it
      sh %(mkdir -p #{ENV['VOLATILE_DIR']}) unless Gem.win_platform?
      t.reenable
    end

    task :install do |t|
      section('INSTALL')
      use_venv = in_venv
      pip_command = use_venv ? 'venv/bin/pip' : 'pip'
      sdk_dir = ENV['SDK_HOME'] || Dir.pwd

      sh %(#{'python -m ' if Gem.win_platform?}#{pip_command} install --upgrade pip setuptools)
      install_requirements('requirements.txt',
                           "--cache-dir #{ENV['PIP_CACHE']}",
                           "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)
      install_requirements('requirements-opt.txt',
                           "--upgrade --cache-dir #{ENV['PIP_CACHE']}",
                           "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)
      install_requirements('requirements-test.txt',
                           "--cache-dir #{ENV['PIP_CACHE']}",
                           "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)

      reqs = Dir.glob(File.join(sdk_dir, '**/requirements.txt')).reject do |path|
        !%r{#{sdk_dir}/embedded/.*$}.match(path).nil? || !%r{#{sdk_dir}\/venv\/.*$}.match(path).nil?
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

    task :run_tests, [:flavor, :mocked] do |t, attr|
      flavors = attr[:flavor]
      sdkhome = ENV['SDK_HOME'] || Dir.pwd
      mocked = attr[:mocked] || false
      filter = ENV['NOSE_FILTER'] || '1'
      nose_command = in_venv ? 'venv/bin/nosetests' : 'nosetests'

      mock_filter = mocked ? "mock" : "not mock"
      nose = if flavors.include?('default')
               "(not requires) and #{filter} and #{mock_filter}"
             else
               "(requires in ['#{flavors.join("','")}']) and #{filter} and #{mock_filter}"
             end

      tests_directory, = integration_tests(sdkhome)
      unless flavors.include?('default')
        tests_directory = tests_directory.reject do |test|
          /.*#{flavors}.*$/.match(test).nil?
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

    task execute: [:before_install, :install, :before_script, :script]
  end
end
