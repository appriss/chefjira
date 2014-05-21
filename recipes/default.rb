
#
# Cookbook Name:: jira
# Recipe:: default
#
# Copyright 2013, Appriss Inc.
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'java'
#include_recipe 'apache2'
#include_recipe 'apache2::mod_rewrite'
#include_recipe 'apache2::mod_proxy'
#include_recipe 'apache2::mod_ssl'
include_recipe 'labrea'


jira_base_dir = File.join(node[:jira][:install_path],node[:jira][:base_name])

# Create a system user account on the server to run the Atlassian Jira server
user node[:jira][:run_as] do
  system true
  shell  '/bin/bash'
  action :create
end

# Create a home directory for the Atlassian Stash user
directory node[:jira][:home] do
  owner node[:jira][:run_as]
end

# Install or Update the Atlassian Stash package
labrea "atlassian-jira" do
  source node[:jira][:source]
  version node[:jira][:version]
  install_dir node[:jira][:install_path]
  config_files [File.join("atlassian-jira-#{node[:jira][:version]}-standalone","atlassian-jira","WEB-INF","classes","jira-application.properties"),
	        File.join("atlassian-jira-#{node[:jira][:version]}","conf","server.xml")]
  notifies :run, "execute[configure jira permissions]", :immediately
  override_path "atlassian-jira-#{node[:jira][:version]}-standalone"
end

# Set the permissions of the Atlassian Jira directory
execute "configure jira permissions" do
  command "chown -R #{node[:jira][:run_as]} #{node[:jira][:install_path]} #{node[:jira][:home]}"
  action :nothing
end

# Install main config file
template ::File.join(jira_base_dir,"atlassian-jira","WEB-INF","classes","jira-application.properties") do
  owner node[:jira][:run_as]
  source "jira-application.properties.erb"
  mode 0644
end

# Add the server.xml configuration for Crowd using the erb template
template ::File.join(jira_base_dir,"conf","server.xml") do
  owner node[:jira][:run_as]
  source "server.xml.erb"
  mode 0644
end

# Install service wrapper

wrapper_home = File.join(jira_base_dir,node[:jira][:jsw][:base_name])

labrea node[:jira][:jsw][:base_name] do
  source node[:jira][:jsw][:source]
  version node[:jira][:jsw][:version]
  install_dir node[:jira][:jsw][:install_path]
  config_files [File.join("#{node[:jira][:jsw][:base_name]}-#{node[:jira][:jsw][:version]}","conf","wrapper.conf")]
  notifies :run, "execute[configure wrapper permissions]", :immediately
end

# Configure wrapper permissions
execute "configure wrapper permissions" do
  command "chown -R #{node[:jira][:run_as]} #{wrapper_home} #{wrapper_home}/*"
  action :nothing
end


# Configure wrapper
template File.join(wrapper_home,"conf","wrapper.conf") do
  owner node[:jira][:run_as]
  source "wrapper.conf.erb"
  mode 0644
  variables({
    :wrapper_home => wrapper_home,
    :jira_base_dir => jira_base_dir,
    :newrelic_jar => File.join(jira_base_dir,'newrelic', 'newrelic.jar')
  })
end

#Install NewRelic if configured
if node[:jira][:newrelic][:enabled]
  include_recipe 'newrelic::java-agent'
  #We need to explictly disable JSP autoinstrument
  newrelic_conf = File.join(jira_base_dir, 'newrelic', 'newrelic.yml')
  ruby_block "disable autoinstrument for JSP pages." do 
    block do
      f = Chef::Util::FileEdit.new(newrelic_conf)
      f.search_file_replace(/auto_instrument: true/,'auto_instrument: false')
      f.write_file
    end
  end
end

# Create wrapper startup script
template File.join(wrapper_home,"bin","jira") do
  owner node[:jira][:run_as]
  source "jira-startup.erb"
  mode 0755
  variables({
    :wrapper_home => wrapper_home
  })
  notifies :run, "execute[install startup script]", :immediately
end

execute "install startup script" do
  command "#{::File.join(wrapper_home,"bin","jira")} install"
  action :nothing
  returns [0,1]
  notifies :restart, "service[jira]", :immediately
end

service "jira" do
  action :nothing
end

# Enable the Apache2 proxy_http module
#execute "a2enmod proxy_http" do
#  command "/usr/sbin/a2enmod proxy_http"
#  notifies :restart, resources(:service => "apache2")
#  action :run
#end

# Add the setenv.sh environment script using the erb template
#template File.join("#{node[:jira][:install_path]}/atlassian-jira","/bin/setenv.sh") do
#  owner node[:jira][:run_as]
#  source "setenv.sh.erb"
#  mode 0644
#end

# Setup the virtualhost for Apache
#web_app "jira" do
#  docroot File.join("#{node[:jira][:install_path]}/atlassian-jira","/") 
#  template "jira.vhost.erb"
#  server_name node[:fqdn]
#  server_aliases [node[:hostname], "jira"]
#end
