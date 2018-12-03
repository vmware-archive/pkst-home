#! /usr/bin/env ruby

require "net/http"
require "uri"
require 'optparse'
require 'json'
require 'pp'
require 'open3'
require 'mkmf'

lock_file_url = ARGV.first
unless lock_file_url
  fail 'Must supply the URL to the lock file'
end

env_lock = load_lock_file_from_url(url: lock_file_url)
env_dir = "#{Dir.home}/workspace/#{env_lock[:name]}"
run_command(cmd: "mkdir -p #{env_dir}")

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
                                      ops_manager_hostname: env_lock[:ops_manager_dns]))

BEGIN {
  def load_lock_file_from_url(url:)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = http.read_timeout = 5
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.code != "200"
      fail "got error from #{url}. response code: #{response.code}. response: #{response.body}"
    end
    JSON.parse(response.body, symbolize_names: true)
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
    @om ||= find_executable 'om'
    unless @om
      fail "cannot find om on path"
    end
    @om
  end

  def lpass
    @lpass ||= find_executable 'lpass'
    unless @lpass
      fail "cannot find lpass on path"
    end
    @lpass
  end

  def envrc(client:, client_secret:, director_ip:, ca_cert_path:, ssh_key_path:, ops_manager_hostname:)
    <<~ENVRC
      export BOSH_CLIENT=#{client}
      export BOSH_CLIENT_SECRET=#{client_secret}
      export BOSH_CA_CERT=#{ca_cert_path}
      export BOSH_ENVIRONMENT=#{director_ip}
      export BOSH_ALL_PROXY=ssh+socks5://ubuntu@#{ops_manager_hostname}:22?private-key=#{ssh_key_path}
      export CREDHUB_PROXY=ssh+socks5://ubuntu@#{ops_manager_hostname}:22?private-key=#{ssh_key_path}
    ENVRC
  end

  def parse_bosh_creds(bosh_json:)
    s = JSON.parse(bosh_json, symbolize_names: true)[:credential]
    s.split.map {|i| i.split('=')}.inject({}) {|memo, cred| memo[cred.first.to_sym] = cred.last; memo}
  end

  def om_opts(env_lock:)
    {
        "OM_USERNAME" => env_lock[:ops_manager][:username],
        "OM_PASSWORD" => env_lock[:ops_manager][:password],
        "OM_TARGET" => env_lock[:ops_manager][:url],
    }
  end
}

