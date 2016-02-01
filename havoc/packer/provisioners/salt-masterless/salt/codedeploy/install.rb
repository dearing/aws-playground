#!/usr/bin/env ruby

##################################################################
# This part of the code might be running on Ruby versions other
# than 2.0. Testing on multiple Ruby versions is required for
# changes to this part of the code.
##################################################################

class Proxy
  instance_methods.each do |m|
    undef_method m unless m =~ /(^__|^send$|^object_id$)/
  end

  def initialize(*targets)
    @targets = targets
  end

  protected

  def method_missing(name, *args, &block)
    @targets.map do |target|
      target.__send__(name, *args, &block)
    end
  end
end

log_file_path = "/tmp/codedeploy-agent.update.log"

require 'logger'

if($stdout.isatty)
  # if we are being run in a terminal, log to stdout and the log file.
  @log = Logger.new(Proxy.new(File.open(log_file_path, 'a+'), $stdout))
else
  # keep at most 2MB of old logs rotating out 1MB at a time
  @log = Logger.new(log_file_path, 2, 1048576)
  # make sure anything coming out of ruby ends up in the log file
  $stdout.reopen(log_file_path, 'a+')
  $stderr.reopen(log_file_path, 'a+')
end

@log.level = Logger::INFO

begin
  require 'fileutils'
  require 'openssl'
  require 'open-uri'
  require 'uri'
  require 'getoptlong'
  require 'tempfile'

  def usage
    print <<EOF

install [--sanity-check] <package-type>
   --sanity-check [optional]
   package-type: 'rpm', 'deb', or 'auto'

Installs fetches the latest package version of the specified type and
installs it. rpms are installed with yum; debs are installed using gdebi.

This program is invoked automatically to update the agent once per day using
the same package manager the codedeploy-agent is initially installed with.

To use this script for a hands free install on any system specify a package
type of 'auto'. This will detect if yum or gdebi is present on the system
and select the one present if possible. If both rpm and deb package managers
are detected the automatic detection will abort
When using the automatic setup, if the system has apt-get but not gdebi,
the gdebi will be installed using apt-get first.

If --sanity-check is specified, the install script will wait for 3 minutes post installation
to check for a running agent.

This install script needs Ruby version 2.0.x installed as a prerequisite.
If you do not have Ruby version 2.0.x installed, please install it first.

EOF
  end

  # check ruby version, only version 2.0.x works
  def check_ruby_version_and_symlink
    @log.info("Starting Ruby version check.")
    actual_ruby_version = RUBY_VERSION.split('.').map{|s|s.to_i}
    left_bound = '2.0.0'.split('.').map{|s|s.to_i}
    right_bound = '2.1.0'.split('.').map{|s|s.to_i}
    if !(File.exist?('/usr/bin/ruby2.0'))
      if (File.symlink?('/usr/bin/ruby2.0'))
        @log.error("The symlink /usr/bin/ruby2.0 already exists, but it's linked to a non-existent directory or executable file.")
        exit(1)

        # The spaceship operator is a rarely used Ruby feature - particularly how it interacts with arrays.
        # Not all languages that have it handle that case the same way.
      elsif ((actual_ruby_version <=> left_bound) < 0 || (actual_ruby_version <=> right_bound) >= 0)
        @log.error("Current running Ruby version for "+ENV['USER']+" is "+RUBY_VERSION+", but Ruby version 2.0.x needs to be installed.")
        @log.error('If you have Ruby version 2.0.x installed for other users, please create a symlink to /usr/bin/ruby2.0.')
        @log.error("Otherwise please install Ruby 2.0.x for "+ENV['USER']+" user.")
        exit(1)
      else
        ruby_interpreter_path = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["RUBY_INSTALL_NAME"] + RbConfig::CONFIG["EXEEXT"])
        File.symlink(ruby_interpreter_path, '/usr/bin/ruby2.0')
      end
    end
  end

  def parse_args()
    if (ARGV.length > 4)
      usage
      @log.error('Too many arguments.')
      exit(1)
    elsif (ARGV.length < 1)
      usage
      @log.error('Expected package type as argument.')
      exit(1)
    end

    @sanity_check = false
    @reexeced = false
    
    @args = Array.new(ARGV)
    opts = GetoptLong.new(['--sanity-check', GetoptLong::NO_ARGUMENT], ['--help', GetoptLong::NO_ARGUMENT], ['--re-execed', GetoptLong::NO_ARGUMENT])
    opts.each do |opt, args|
      case opt
      when '--sanity-check'
        @sanity_check = true
      when '--help'
        usage
      when '--re-execed'
        @reexeced = true
      end
    end
    if (ARGV.length < 1)
      usage
      @log.error('Expected package type as argument.')
      exit(1)
    end
    @type = ARGV.shift.downcase;
  end

  def force_ruby20()
    # change interpreter when symlink /usr/bin/ruby2.0 exists, but running with lower ruby version
    actual_ruby_version = RUBY_VERSION.split('.').map{|s|s.to_i}
    left_bound = '2.0.0'.split('.').map{|s|s.to_i}
    right_bound = '2.1.0'.split('.').map{|s|s.to_i}
    if (actual_ruby_version <=> left_bound) < 0
      if(!@reexeced)
        @log.info("The current Ruby version is not 2.0.x! Restarting the installer with /usr/bin/ruby2.0")
        exec('/usr/bin/ruby2.0', __FILE__, '--re-execed' , *@args)
      else
        @log.error('The Ruby version in /usr/bin/ruby2.0 is '+RUBY_VERSION+', but this must be Ruby version 2.0.x. Installation cannot continue.')
        @log.error('If you have Ruby version 2.0.x installed, please correct the symlink. Otherwise, please install Ruby 2.0')
        exit(1)
      end
    elsif (actual_ruby_version <=> right_bound) >= 0
      @log.warn('The Ruby version in /usr/bin/ruby2.0 is '+RUBY_VERSION+', but this must be Ruby version 2.0.x. Attempting to install anyway.')
      @log.warn('If you have Ruby version 2.0.x installed, please correct the symlink. Otherwise, please install Ruby 2.0')
    end
  end

  if (Process.uid != 0)
    @log.error('Must run as root to install packages')
    exit(1)
  end
  
  parse_args()

  ########## Force running as Ruby 2.0 or fail here       ##########
  check_ruby_version_and_symlink()
  force_ruby20()
  
  def run_command(*args)
    exit_ok = system(*args)
    $stdout.flush
    $stderr.flush
    @log.debug("Exit code: #{$?.exitstatus}")
    return exit_ok
  end

  def get_ec2_metadata_region
    begin
      uri = URI.parse('http://169.254.169.254/latest/meta-data/placement/availability-zone')
      az = uri.read(:read_timeout => 120)
      az.strip
    rescue
      @log.warn("Could not get region from EC2 metadata service at '#{uri.to_s}'")
      return nil
    end

    if (az !~ /[a-z]{2}-[a-z]+-\d+[a-z]/)
      @log.warn("Invalid availability zone name: '#{az}'.")
      return nil
    else
      return az.chop
    end
  end

  def get_region
    @log.info('Checking AWS_REGION environment variable for region information...')
    region = ENV['AWS_REGION']
    return region if region

    @log.info('Checking EC2 metadata service for region information...')
    region = get_ec2_metadata_region
    return region if region

    @log.info('Using fail-safe default region: us-east-1')
    return 'us-east-1'
  end

  def get_s3_uri(region, bucket, key)
    if (region == 'us-east-1')
      URI.parse("https://s3.amazonaws.com/#{bucket}/#{key}")
    else
      URI.parse("https://s3-#{region}.amazonaws.com/#{bucket}/#{key}")
    end
  end

  def get_package_from_s3(region, bucket, key, package_file)
    @log.info("Downloading package from bucket #{bucket} and key #{key}...")

    uri = get_s3_uri(region, bucket, key)

    # stream package file to disk
    begin
      uri.open(:ssl_verify_mode => OpenSSL::SSL::VERIFY_PEER, :redirect => true, :read_timeout => 120) do |s3|
        package_file.write(s3.read)
      end
    rescue OpenURI::HTTPError => e
      @log.error("Could not find package to download at '#{uri.to_s}'")
      exit(1)
    end
  end

  def get_version_file_from_s3(region, bucket, key)
    @log.info("Downloading version file from bucket #{bucket} and key #{key}...")

    uri = get_s3_uri(region, bucket, key)

    begin
      require 'json'

      version_string = uri.read(:ssl_verify_mode => OpenSSL::SSL::VERIFY_PEER, :redirect => true, :read_timeout => 120)
      JSON.parse(version_string)
    rescue OpenURI::HTTPError => e
      @log.error("Could not find version file to download at '#{uri.to_s}'")
      exit(1)
    end
  end

  def install_from_s3(region, bucket, version_file_key, type, install_cmd)
    version_data = get_version_file_from_s3(region, bucket, version_file_key)

    package_key = version_data[type]
    package_base_name = File.basename(package_key)
    package_extension = File.extname(package_base_name)
    package_name = File.basename(package_base_name, package_extension)
    package_file = Tempfile.new(["#{package_name}.tmp-", package_extension]) # unique file with 0600 permissions

    get_package_from_s3(region, bucket, package_key, package_file)
    package_file.close

    install_cmd << package_file.path
    @log.info("Executing `#{install_cmd.join(" ")}`...")

    if (!run_command(*install_cmd))
      @log.error("Error installing #{package_file.path}.")
      package_file.unlink
      exit(1)
    end

    package_file.unlink
  end

  def do_sanity_check(cmd)
    if @sanity_check
      @log.info("Waiting for 3 minutes before I check for a running agent")
      sleep(3 * 60)
      res = run_command(cmd, 'codedeploy-agent', 'status')
      if (res.nil? || res == false)
        @log.info("No codedeploy agent seems to be running. Starting the agent.")
        run_command(cmd, 'codedeploy-agent', 'start-no-update')
      end
    end
  end

  @log.info("Starting update check.")

  if (@type == 'auto')
    @log.info('Attempting to automatically detect supported package manager type for system...')

    has_yum = run_command('which yum >/dev/null 2>/dev/null')
    has_apt_get = run_command('which apt-get >/dev/null 2>/dev/null')
    has_gdebi = run_command('which gdebi >/dev/null 2>/dev/null')
    has_zypper = run_command('which zypper >/dev/null 2>/dev/null')

    if (has_yum && (has_apt_get || has_gdebi))
      @log.error('Detected both supported rpm and deb package managers. Please specify which package type to use manually.')
      exit(1)
    end

    if(has_yum)
      @type = 'rpm'
    elsif(has_zypper)
      @type = 'zypper'
    elsif(has_gdebi)
      @type = 'deb'
    elsif(has_apt_get)
      @type = 'deb'

      @log.warn('apt-get found but no gdebi. Installing gdebi with `apt-get install gdebi -y`...')
      #use -y to answer yes to confirmation prompts
      if(!run_command('/usr/bin/apt-get', 'install', 'gdebi', '-y'))
        @log.error('Could not install gdebi.')
        exit(1)
      end
    else
      @log.error('Could not detect any supported package managers.')
      exit(1)
    end
  end

  region = get_region
  bucket = "aws-codedeploy-#{region}"
  version_file_key = 'latest/VERSION'

  case @type
  when 'help'
    usage
  when 'rpm'
    #use -y to answer yes to confirmation prompts
    install_cmd = ['/usr/bin/yum', '-y', 'localinstall']
    install_from_s3(region, bucket, version_file_key, @type, install_cmd)
    do_sanity_check('/sbin/service')
  when 'deb'
    #use -n for non-interactive mode
    #use -o to not overwrite config files unless they have not been changed
    install_cmd = ['/usr/bin/gdebi', '-n', '-o', 'Dpkg::Options::=--force-confdef', '-o', 'Dpg::Options::=--force-confold']
    install_from_s3(region, bucket, version_file_key, @type, install_cmd)
    do_sanity_check('/usr/sbin/service')
  when 'zypper'
    #use -n for non-interactive mode
    install_cmd = ['/usr/bin/zypper', 'install', '-n']
    install_from_s3(region, bucket, version_file_key, 'rpm', install_cmd)
  else
    @log.error("Unsupported package type '#{@type}'")
    exit(1)
  end

  @log.info("Update check complete.")
  @log.info("Stopping updater.")

rescue SystemExit => e
  # don't log exit() as an error
  raise e
rescue Exception => e
  # make sure all unhandled exceptions are logged to the log
  @log.error("Unhandled exception: #{e.inspect}")
  e.backtrace.each do |line|
    @log.error("  at " + line)
  end
  exit(1)
end
