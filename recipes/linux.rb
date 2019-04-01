#
# Cookbook:: chef-contrast-teamserver
# Recipe:: linux
#
# Copyright:: 2019, The Authors, All Rights Reserved.

# Install MySQL libaio package
# Contrast TeamServer on Linux requires this package as a dependency
case node['platform']
when 'redhat', 'centos', 'fedora', 'suse'
  package 'libaio'
when 'debian', 'ubuntu'
  package 'libaio1'
  package 'libaio-dev'
end

# Create temp directory for Contrast TeamServer installer
directory '/tmp/contrast-installer' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Transfer the PhantomJS script to the temp directory; this script will be used to download the Contrast TeamServer installer
cookbook_file '/tmp/contrast-installer/teamserver_installer.js' do
  source 'teamserver_installer.js'
end

# Get Contrast Hub credentials from a data bag
# Load the data bag item for the Contrast Hub credentials into a variable
hubcreds = data_bag_item('contrasthub', 'creds')

# Execute the PhantomJS script that will lead to downloading the TeamServer installer
execute 'phantomjs-teamserver_installer' do
  sensitive true
  case node['platform']
  when 'centos'
    command "/usr/local/src/phantomjs-2.1.1-linux-x86_64/bin/phantomjs teamserver_installer.js #{hubcreds['username']} #{hubcreds['password']} linux #{node['chef-contrast-teamserver']['linux_installer']}"
  else
    command "phantomjs teamserver_installer.js #{hubcreds['username']} #{hubcreds['password']} linux #{node['chef-contrast-teamserver']['linux_installer']}"
  end
  cwd '/tmp/contrast-installer'
  notifies :touch, 'file[/tmp/contrast-installer/download_installer.sh]', :immediately
end

# Change permissions of the 'download_installer.sh' file created by the PhantomJS script
file '/tmp/contrast-installer/download_installer.sh' do
  mode '0755'
  action :nothing
end

# Execute the TeamServer installer download script produced by the PhantomJS script
execute 'download_teamserver' do
  command 'sudo ./download_installer.sh'
  cwd '/tmp/contrast-installer'
  not_if { ::File.zero?('/tmp/contrast-installer/download_installer.sh') }
  notifies :touch, 'file[/tmp/contrast-installer/contrast_installer.sh]', :immediately
end

# Change permissions of the 'contrast_installer.sh' file so that it's executable
file '/tmp/contrast-installer/contrast_installer.sh' do
  mode '0755'
  action :nothing
end

# Transfer the license file to the temp directory
cookbook_file "\/tmp\/contrast-installer\/#{node['chef-contrast-teamserver']['license']}" do
  source node['chef-contrast-teamserver']['license']
end

# Create variables files to pass to the unattended install of TeamServer
template '/tmp/contrast-installer/vars.txt' do
  source 'vars.txt.erb'
end

# Execute unattended install of TeamServer Linux installer with install configuration file (from template file)
execute 'Run Contrast TeamServer installer' do
  command 'sudo ./contrast_installer.sh -q -varfile /tmp/contrast-installer/vars.txt'
  cwd '/tmp/contrast-installer'
  not_if { ::File.zero?('/tmp/contrast-installer/contrast_installer.sh') }
  not_if { ::File.exist?('/opt/contrast/bin/contrast-server') }
  notifies :restart, 'service[contrast-server]', :delayed
end

# Enable and start the 'contrast-server' service
service 'contrast-server' do
  action [ :enable, :start ]
end

# Contrast TeamServer may not automatically start on Centos, so wait and restart the 'contrast-server' service after a 10-minute delay
case node['platform']
when 'centos'
  cookbook_file '/tmp/contrast-installer/centos_restart.sh' do
    source 'centos_restart.sh'
    mode '0755'
    notifies :run, 'execute[delayed_teamserver_restart]', :delayed
  end

  execute 'delayed_teamserver_restart' do
    command './centos_restart.sh'
    cwd '/tmp/contrast-installer'
    action :nothing
  end
end
