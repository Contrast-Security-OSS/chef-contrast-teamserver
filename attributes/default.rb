# Filename of the Contrast license
default['chef-contrast-teamserver']['license'] = 'prod_dev.lic'

# URL to access TeamServer
default['chef-contrast-teamserver']['teamserver_url'] = "http\://#{node['cloud']['public_ipv4']}\:8080/Contrast"

# TeamServer web port
default['chef-contrast-teamserver']['port'] = '8080'

# Target Contrast TeamServer Windows installer filename
default['chef-contrast-teamserver']['windows_installer'] = 'Contrast-3.6.1.340--NO-CACHE-x64.exe'

# Target Contrast TeamServer Linux installer filename
default['chef-contrast-teamserver']['linux_installer'] = 'Contrast-3.6.1.340-NO-CACHE.sh'
