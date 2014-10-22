include_recipe "kafka"

node[:kafka][:storage].split(',').each do |dir|
  directory dir do
    owner "kafka"
    group "kafka"
    mode "0755"
  end
end

template "/var/app/kafka/current/config/server.properties" do
  source "server.properties"
  owner "root"
  group "kafka"
  mode "0640"
  notifies :restart, "service[kafka]"
end

include_recipe "zookeeper::ruby"

ruby_block "kafka-zk-chroot" do
  block do
    Gem.clear_paths
    require 'zk'
    ZK.new(zookeeper_connect(node[:kafka][:zookeeper][:root], node[:kafka][:zookeeper][:cluster]))
  end
end

systemd_unit "kafka.service"

service "kafka" do
  action [:enable, :start]
end
