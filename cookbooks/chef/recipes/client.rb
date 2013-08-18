case node[:platform]
when "gentoo"
  package "app-admin/chef"
  package "dev-ruby/activesupport"
  package "dev-ruby/knife-dsl"
  package "dev-ruby/airbrake_handler"

  if zentoo?
    package "dev-ruby/madvertise-logging"
  else
    gem_package "madvertise-logging"
  end

  directory "/etc/chef" do
    owner "chef"
    group "root"
    mode "0755"
  end

  directory "/var/log/chef" do
    owner "chef"
    group "chef"
    mode "0755"
  end

  directory "/var/lib/chef/cache" do
    owner "chef"
    group "root"
    mode "0750"
  end

when "debian"
  gem_package "chef"
  gem_package "airbrake_handler"

  directory "/etc/chef" do
    owner "root"
    group "root"
    mode "0755"
  end

  directory "/var/log/chef" do
    owner "root"
    group "root"
    mode "0755"
  end

  directory "/var/lib/chef" do
    owner "root"
    group "root"
    mode "0750"
  end

  directory "/var/lib/chef/cache" do
    owner "root"
    group "root"
    mode "0750"
  end

end

unless solo?
  file "/etc/chef/client.pem" do
    owner "root"
    group "root"
    mode "0400"
  end

  template "/etc/chef/client.rb" do
    source "client.rb"
    owner "root"
    group "root"
    mode "0644"
  end

  timer_envs = %w(production staging)

  cron "chef-client" do
    command "/usr/bin/ruby -E UTF-8 /usr/bin/chef-client -c /etc/chef/client.rb &>/dev/null"
    minute IPAddr.new(node[:primary_ipaddress]).to_i % 60
    action :delete unless timer_envs.include?(node.chef_environment)
    action :delete if systemd_running?
  end

  systemd_unit "chef-client.service"
  systemd_unit "chef-client.timer"

  service "chef-client.timer" do
    action [:enable, :start]
    only_if { systemd_running? }
  end

  # chef-client.service has a condition on this lock
  # so we use it to stop chef-client on testing/staging machines
  file "/run/lock/chef-client.lock" do
    action :delete if timer_envs.include?(node.chef_environment)
  end

  splunk_input "monitor:///var/log/chef/*.log"

  cookbook_file "/etc/logrotate.d/chef" do
    source "chef.logrotate"
    owner "root"
    group "root"
    mode "0644"
  end

  directory "/etc/chef/cache" do
    action :delete
    recursive true
    only_if { File.directory?("/etc/chef/cache") and not File.symlink?("/etc/chef/cache") }
  end

  link "/etc/chef/cache" do
    to "/var/lib/chef/cache"
  end
end

if tagged?("nagios-client")
  nagios_plugin "check_chef_client"

  nrpe_command "check_chef_client" do
    command "/usr/lib/nagios/plugins/check_chef_client 60"
  end

  nagios_service "CHEF-CLIENT" do
    check_command "check_nrpe!check_chef_client"
    servicegroups "chef"
  end
end
