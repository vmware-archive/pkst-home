#! /usr/bin/env ruby

require "net/http"
require "uri"
require 'optparse'
require 'json'
require 'pp'
require 'open3'
require 'pty'
require 'fileutils'
require 'yaml'

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: setup_environment.rb [OPTIONS]"

  opt.on("-u", "--username USERNAME", String, "Lastpass username containing a shared telemetry folder") do |username|
    options[:username] = username
  end

  opt.on("-e", "--environment environment", String, "The environment you want to setup") do |environment|
    options[:environment] = environment
  end

  opt.on("-i", "--url local-file-url", "the url of the environment lock file") do |url|
    options[:url] = url
  end

  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse(ARGV)

if !options[:environment] && !options[:url]
  puts "error: Must supply either the environment or the url to the lock file"
  puts opt_parser
  exit 1
end

if !options[:username]
  puts "error: Must supply the lastpass username"
  puts opt_parser
  exit 1
end

lastpass_username = options[:username]

unless logged_into_lastpass?
  puts "Logging into lastpass"
  lastpass_login(username: lastpass_username)
end

if options[:environment]
  puts "Getting lock file from Last Pass"
  env_lock = load_lock_file_from_lastpass(name: options[:environment])
else
  puts "Loading lock file from url"
  env_lock = load_lock_file_from_url(url: options[:url])
end

env_dir = "#{Dir.home}/workspace/#{env_lock[:name]}"
FileUtils.mkdir_p(env_dir)

puts "Writing SSH key: #{env_dir}/ssh-key"
File.write("#{env_dir}/ssh-key", env_lock[:ops_manager_private_key])
File.chmod(0600, "#{env_dir}/ssh-key")

puts "Fetching root ca cert from ops manager: #{env_lock[:ops_manager][:url]}"
ca_cert_json, _, _ = run_command(cmd: "#{om} -k curl --path /api/v0/security/root_ca_certificate",
                                 env: om_opts(env_lock: env_lock))

ca_cert = JSON.parse(ca_cert_json, symbolize_names: true)
puts "Writing CA cert: #{env_dir}/root_ca_certificate"
File.write("#{env_dir}/root_ca_certificate", ca_cert[:root_ca_certificate_pem])

puts "Fetching BOSH credentials from ops manager"
bosh_creds_json, _, _ = run_command(cmd: "#{om} -k curl --path /api/v0/deployed/director/credentials/bosh_commandline_credentials",
                                    env: om_opts(env_lock: env_lock))

bosh_creds = parse_bosh_creds(bosh_json: bosh_creds_json)

puts "Writing .envrc"
File.write("#{env_dir}/.envrc", envrc(client: bosh_creds[:BOSH_CLIENT],
                                      client_secret: bosh_creds[:BOSH_CLIENT_SECRET],
                                      director_ip: bosh_creds[:BOSH_ENVIRONMENT],
                                      ca_cert_path: "#{env_dir}/root_ca_certificate",
                                      ssh_key_path: "#{env_dir}/ssh-key",
                                      env_lock: env_lock))


target_network_name = "#{env_lock[:name]}-services-subnet"

pipeline_vars = {
    'director_name' => env_lock[:name],
    'network_name' => target_network_name,
    'jumpbox_url' => "#{env_lock[:ops_manager_dns]}:22",
    # hardcoded password is OK. Only used in test environments.
    'mysql_pks_billing_db_password' => 'Zns0tZ3vRHhJYdO8ANZSIJEfchjsAU',
    'bosh_client' => bosh_creds[:BOSH_CLIENT],
    'bosh_client_secret' => bosh_creds[:BOSH_CLIENT_SECRET],
    'credhub_secret' => bosh_creds[:BOSH_CLIENT_SECRET],
    'bosh_ca_cert' => ca_cert[:root_ca_certificate_pem],
    'opsmgr_private_key' => env_lock[:ops_manager_private_key]
}


puts 'Fetching networks from Ops Manager'
networks_list_json, _, _ = run_command(cmd: "#{om} -k curl --path /api/v0/staged/director/networks",
                                       env: om_opts(env_lock: env_lock))
networks_list = JSON.parse(networks_list_json, symbolize_names: true)[:networks]
services_subnet = networks_list.find { |n| n[:name] == target_network_name }
pipeline_vars['azs'] = services_subnet[:subnets].first[:availability_zone_names]


telemetry_test_certs = YAML.load_file(File.join(__dir__, 'telemetry-test-certs.yml'))
pipeline_vars['telemetry_tls'] = telemetry_test_certs

puts 'Writing pipeline-vars.yml'
File.write("#{env_dir}/pipeline-vars.yml", YAML.dump(pipeline_vars))

lpass_creds_entry = "Shared-PKS Telemetry/[#{env_lock[:name]}] OpsMgr Creds"
puts "Creating lpass username/password entry: #{lpass_creds_entry}"
if already_in_lpass?(entry: lpass_creds_entry)
  puts "#{lpass_creds_entry} already exists. Skipping..."
else
  run_command(cmd: lastpass_creds_entry_cmd(env_lock: env_lock, entry: lpass_creds_entry))
end

lpass_lock_file_entry = "Shared-PKS Telemetry/[#{env_lock[:name]}] opsmgr-lock-file.json"
puts "Creating lpass lock file entry: #{lpass_lock_file_entry}"
if already_in_lpass?(entry: lpass_lock_file_entry)
  puts "#{lpass_lock_file_entry} already exists. Skipping..."
else
  run_command(cmd: lastpass_lock_file_entry_cmd(env_lock: env_lock, entry: lpass_lock_file_entry))
end

ssh_config_path = "#{Dir.home}/.ssh/config.d/#{env_lock[:name]}"
puts "Writing ssh config at: #{ssh_config_path}"
FileUtils.mkdir_p("#{Dir.home}/.ssh/config.d/")

File.write(ssh_config_path, ssh_config_directive(env_name: env_lock[:name],
                                                 opsmanager_dns: env_lock[:ops_manager_dns],
                                                 ssh_key_path: "#{env_dir}/ssh-key"))
run_command(cmd: 'lpass sync now')


BEGIN {

  def already_in_lpass?(entry:)
    stdout, _, _ = run_command(cmd: "#{lpass} ls '#{entry}'")
    !stdout.empty?
  end

  def load_lock_file_from_url(url:)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = http.read_timeout = 5
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    unless response.kind_of?(Net::HTTPSuccess)
      fail " got error from #{url}. response code: #{response.code}. response: #{response.body}"
    end
    JSON.parse(response.body, symbolize_names: true)
  end

  def load_lock_file_from_lastpass(name:)
    cmd_string = "lpass show \"Shared-PKS Telemetry/[#{name}] opsmgr-lock-file.json\" --notes"
    lock_file_json, _, _ = run_command(cmd: cmd_string)
    JSON.parse(lock_file_json, symbolize_names: true)
  end

  def run_command(cmd:, env: {})
    puts "$ #{cmd}"
    stdout, stderr, status = Open3.capture3(env.merge(ENV), cmd)
    unless status.success?
      fail "command failed. stderr: #{stderr}. stdout: #{stdout}"
    end
    [stdout, stderr, status]
  end

  def om
    @om ||= `which om`.chomp
    if @om.empty?
      fail 'cannot find om on path'
    end
    @om
  end

  def lpass
    @lpass ||= `which lpass`.chomp
    if @lpass.empty?
      fail "cannot find lpass on path"
    end
    @lpass
  end

  def envrc(client:, client_secret:, director_ip:, ca_cert_path:, ssh_key_path:, env_lock:)
    ops_manager_hostname = env_lock[:ops_manager_dns]
    bosh_vars = <<~ENVRC
      export BOSH_CLIENT=#{client}
      export BOSH_CLIENT_SECRET=#{client_secret}
      export BOSH_CA_CERT=#{ca_cert_path}
      export BOSH_ENVIRONMENT=#{director_ip}
      export BOSH_ALL_PROXY=ssh+socks5://ubuntu@#{ops_manager_hostname}:22?private-key=#{ssh_key_path}
      export CREDHUB_PROXY=ssh+socks5://ubuntu@#{ops_manager_hostname}:22?private-key=#{ssh_key_path}
    ENVRC
    om_vars = om_opts(env_lock: env_lock).map { |k, v| "export #{k}=#{v}" }.join("\n")
    [bosh_vars, om_vars].join("\n")
  end

  def parse_bosh_creds(bosh_json:)
    s = JSON.parse(bosh_json, symbolize_names: true)[:credential]
    s.split.map { |i| i.split('=') }.inject({}) { |memo, cred| memo[cred.first.to_sym] = cred.last; memo }
  end

  def om_opts(env_lock:)
    {
        "OM_USERNAME" => env_lock[:ops_manager][:username],
        "OM_PASSWORD" => env_lock[:ops_manager][:password],
        "OM_TARGET" => env_lock[:ops_manager][:url],
    }
  end

  def lastpass_creds_entry_cmd(env_lock:, entry:)
    <<~LPASS
      printf "Username: #{env_lock[:ops_manager][:username]}\nPassword: #{env_lock[:ops_manager][:password]}\nURL: #{env_lock[:ops_manager][:url]}" |
      #{lpass} add --non-interactive "#{entry}"
    LPASS
  end

  def lastpass_lock_file_entry_cmd(env_lock:, entry:)
    <<~LPASS
      gecho -E '#{env_lock.to_json}' |
      #{lpass} add --non-interactive --notes "#{entry}"
    LPASS
  end

  def squish(str)
    str.gsub(/\A[[:space:]]+/, '').gsub(/[[:space:]]+\z/, '').gsub(/[[:space:]]+/, ' ')
  end

  def logged_into_lastpass?
    _, _, status = Open3.capture3("#{lpass} sync")
    status.success?
  end

  def lastpass_login(username:, trust: false)
    PTY.open
    puts "Logging into LastPass"
    pid = fork do
      if trust
        exec("#{lpass} login --trust #{username}")
      else
        exec("#{lpass} login #{username}")
      end
    end
    Signal.trap(:INT) {}
    _, status = Process.waitpid2(pid)
    unless status.success?
      fail 'error logging into lastpass'
    end
  ensure
    Signal.trap(:INT, nil)
  end

  def ssh_config_directive(env_name:, opsmanager_dns:, ssh_key_path:)
    <<~SSH
      Host #{env_name} #{opsmanager_dns}
        HostName #{opsmanager_dns}
        User ubuntu
        IdentityFile #{ssh_key_path}
    SSH
  end
}


