#
# Cookbook Name:: jira
# Attributes:: jira
#
# Copyright 2008-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# The openssl cookbook supplies the secure_password library to generate random passwords
default[:jira][:virtual_host_name]  = "jira.#{domain}"
default[:jira][:virtual_host_alias] = "jira.#{domain}"
# type-version-standalone
default[:jira][:base_name]	    = "atlassian-jira"
default[:jira][:version]           = "2.1.1"
default[:jira][:install_path]      = "/opt/jira"
default[:jira][:home]              = "/var/lib/jira"
default[:jira][:source]            = "http://www.atlassian.com/software/jira/downloads/binary/#{node[:jira][:base_name]}-#{node[:jira][:version]}.tar.gz"
default[:jira][:run_as]          = "jira"
default[:jira][:min_mem]	    = 384
default[:jira][:max_mem]	    = 768
default[:jira][:ssl]		    = true
default[:jira][:timezone]		= nil
default[:jira][:database][:type]   = "mysql"
default[:jira][:database][:host]     = "localhost"
default[:jira][:database][:user]     = "jira"
default[:jira][:database][:name]     = "jira"
default[:jira][:service][:type]      = "jsw"
if node[:opsworks][:instance][:architecture]
  default[:jira][:jsw][:arch]          = node[:opsworks][:instance][:architecture].gsub!(/_/,"-")
else
  default[:jira][:jsw][:arch]          = node[:kernel][:machine].gsub!(/_/,"-")
end
default[:jira][:jsw][:base_name]     = "wrapper-linux-#{node[:jira][:jsw][:arch]}"
default[:jira][:jsw][:version]       = "3.5.20"
default[:jira][:jsw][:install_path]  = ::File.join(node[:jira][:install_path],"#{node[:jira][:base_name]}")
default[:jira][:jsw][:source]        = "http://wrapper.tanukisoftware.com/download/#{node[:jira][:jsw][:version]}/wrapper-linux-#{node[:jira][:jsw][:arch]}-#{node[:jira][:jsw][:version]}.tar.gz"
default[:jira][:newrelic][:enabled]  = false
default[:jira][:newrelic][:version]  = "3.5.0"
default[:jira][:newrelic][:app_name] = node['hostname']

# Confluence doesn't support OpenJDK http://jira.atlassian.com/browse/CONF-16431
# FIXME: There are some hardcoded paths like JAVA_HOME
set[:java][:install_flavor]    = "oracle"
normal[:newrelic][:'java-agent'][:install_dir]   = ::File.join(node[:jira][:install_path],node[:jira][:base_name],"newrelic")
normal[:newrelic][:'java-agent'][:app_user] = node[:jira][:run_as]
normal[:newrelic][:'java-agent'][:app_group] = node[:jira][:run_as]
normal[:newrelic][:'java-agent'][:https_download] = "https://download.newrelic.com/newrelic/java-agent/newrelic-agent/#{node[:jira][:newrelic][:version]}/newrelic-agent-#{node[:jira][:newrelic][:version]}.jar"
normal[:newrelic][:'java-agent'][:jar_file] = "newrelic-agent-#{node[:jira][:newrelic][:version]}.jar"
normal[:newrelic][:application_monitoring][:logfile] = ::File.join(node[:jira][:home], "log", "newrelic.log")
normal[:newrelic][:application_monitoring][:appname] = node[:jira][:newrelic][:app_name]


