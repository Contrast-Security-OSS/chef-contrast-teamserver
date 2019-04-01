#
# Cookbook:: chef-contrast-teamserver
# Recipe:: windows
#
# Copyright:: 2019, The Authors, All Rights Reserved.

# Install Microsoft Visual C++ 2013 run-time
# Contrast TeamServer on Windows requires Visual C++ 2013 run-time dependencies
include_recipe 'vcruntime::vc12'

# Create temp directory for Contrast TeamServer installer
directory 'C:\temp' do
  rights :full_control, 'Everyone'
  inherits false
  action :create
end

# Transfer the PhantomJS script to the temp directory; this script will be used to download the Contrast TeamServer installer
cookbook_file 'C:\temp\teamserver_installer.js' do
  source 'teamserver_installer.js'
end

# Get Contrast Hub credentials from a data bag
# Load the data bag item for the Contrast Hub credentials into a variable
hubcreds = data_bag_item('contrasthub', 'creds')

# Execute the PhantomJS script that will lead to downloading the TeamServer installer
execute 'phantomjs-teamserver_installer' do
  sensitive true
  command "phantomjs teamserver_installer.js #{hubcreds['username']} #{hubcreds['password']} windows #{node['chef-contrast-teamserver']['windows_installer']}"
  cwd 'C:\temp'
end

# Execute the TeamServer installer download script produced by the PhantomJS script
powershell_script 'download_teamserver' do
  code '.\download_installer.ps1'
  cwd 'C:\temp'
  only_if { ::File.exist?('C:\temp\download_installer.ps1') }
  notifies :touch, 'file[C:\temp\contrast_installer.exe]', :immediately
end

# Change permissions of the 'contrast_installer.sh' file so that it's executable
file 'C:\temp\contrast_installer.exe' do
  mode '0755'
  action :nothing
end

# Transfer the license file to the temp directory
cookbook_file "C:\\temp\\#{node['chef-contrast-teamserver']['license']}" do
  source node['chef-contrast-teamserver']['license']
end

# Create variables files to pass to the unattended install of TeamServer
template 'C:\temp\vars.txt' do
  source 'vars.txt.erb'
end

# Execute unattended install of TeamServer Windows installer with install configuration file (from template file)
execute 'Run Contrast TeamServer installer' do
  command 'contrast_installer.exe -q -varfile C:\temp\vars.txt'
  cwd 'C:\temp'
  not_if { ::File.exist?('C:\Program Files\Contrast\bin\contrast-server.exe') }
  not_if { ::File.zero?('C:\temp\contrast_installer.exe') }
  notifies :create, 'windows_firewall_rule[teamserver]', :delayed
end

# Configure Windows firewall rule to allow traffic on the TeamServer port
windows_firewall_rule 'teamserver' do
  local_port node['chef-contrast-teamserver']['port']
  protocol 'TCP'
  firewall_action :allow
end
