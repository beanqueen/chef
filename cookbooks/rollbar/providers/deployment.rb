#
# Cookbook Name:: rollbar
# LWRP: deployment
#
# Notify deployment to rollbar
#
# Copypright 2014, Appsdeck
#
# License BSD version 3
#
require 'uri'
require 'net/http'

def whyrun_supported?
  true
end

action :nothing do
end

action :notify do
  if new_resource.revision
    revision = new_resource.revision
  elsif new_resource.path
    path = new_resource.path
    cwd = Dir.getwd

    Dir.chdir path
    revision=`git log -n 1 --pretty=format:"%H"`
    Dir.chdir cwd
  else
    raise "A revision or a path should be provided"
  end

  payload = {
    "access_token" => new_resource.token,
    "environment" => new_resource.env,
    "local_username" => node[:fqdn],
    "revision" => revision
  }
  payload["comment"] = new_resource.comment if new_resource.comment

  uri = URI(node[:rollbar][:endpoint])
  res = nil
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    req = Net::HTTP::Post.new(uri.request_uri)
    req.form_data = payload
    res = http.request(req)
  end
end
