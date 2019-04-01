#
# Cookbook:: chef-contrast-teamserver
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

# Install Google Chrome (for convenience instead of using IE)
include_recipe 'chrome::default'

# Install PhantomJS
include_recipe 'phantomjs2::default'

# Install Contrast Security TeamServer
case node['platform']
when 'windows'
  include_recipe 'chef-contrast-teamserver::windows'
when 'redhat', 'centos', 'fedora', 'suse', 'debian', 'ubuntu'
  include_recipe 'chef-contrast-teamserver::linux'
else
  Chef::Log.warn('Contrast Security TeamServer cannot be installed on this platform using this cookbook.')
end
