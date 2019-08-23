# Chef cookbook to install Contrast Security's TeamServer

## Overview
This Chef cookbook will automate the installation of [Contrast Security](https://www.contrastsecurity.com/)'s TeamServer on Linux or Windows.  It requires that the target system has access to the Internet in order to connect to Contrast Hub to download the target installer file.

The cookbook executes the following general steps:
1. Installs Google Chrome (which is used later by PhantomJS)
2. Installs necessary dependencies...
  * Microsoft Visual C++ 2013 Redistributable package on Windows
  * Libaio packages on Linux
3. Installs PhantomJS (which is used to download the target TeamServer installer)
4. Executes a PhantomJS script that logs into Contrast Hub (https://hub.contrastsecurity.com), finds the target TeamServer installer, and builds a command-line script to download the installer
5. Downloads the TeamServer installer file using the aforementioned command-line script
6. Runs the Contrast TeamServer installer using the unattended install option

Please note that this cookbook can take some time to run due to downloading a large installation file and then executing the installation process.  Please expect it to take anywhere from 30 minutes to 3 hours depending on whether a TeamServer 'CACHE' or 'NO CACHE' installer is used (https://docs.contrastsecurity.com/installation-setupinstall.html#download).

## Prerequisites
You will need to supply your own Contrast license file. More details about where to place your license files is below.

### Add your Contrast license to the cookbook files
A license file is purposely not included with this cookbook.  You will need to acquire your own license from your Contrast Account Team or Contrast Support.  After acquiring your license:
1. Copy/move the license file to the cookbook's `files/default` directory
2. Edit the `default.rb` attributes file (`.../attributes/default.rb`) and modify the value for `default['contrast-teamserver']['license']` to match the filename of your license file.

### Attributes
Users must provide the following information in order to run this cookbook:
* `node['chef-contrast-teamserver']['license']` = Valid Contrast license file and its filename
* `node['chef-contrast-teamserver']['windows_installer']` = Filename of the target Windows TeamServer installer
* `node['chef-contrast-teamserver']['linux_installer']` = Filename of the target Linux TeamServer installer
* `node['chef-contrast-teamserver']['teamserver_url']` = Desired URL for TeamServer
* `node['chef-contrast-teamserver']['port']` = Desired default port for TeamServer

### Creating the encrypted data bag to store your Contrast Hub username and password
Since this cookbook requires credentials to log into Contrast Hub in order to download the target TeamServer installer, it utilizes an [encrypted data bag](https://docs.chef.io/secrets.html) to pass your Hub username and password to the target Chef-managed system.
You can create the encrypted data bag using Chef's `knife` utility.

Please note that this cookbook requires that the data bag be named `contrasthub` and the data bag items must be called `creds` with your Contrast Hub credentials named `username` and `password`.

The general steps to create the encrypted data bag are:
1. First start by creating your secret key; for example with OpenSSL, run `openssl rand -base64 512 | tr -d '\r\n' > encrypted_data_bag_secret`
2. Place your new `encrypted_data_bag_secret` under your cookbook's `test/integration/default` directory, which is where this cookbook's `.kitchen.yml` expects it; otherwise, update the `.kitchen.yml` to point to the location of your secret key file
3. Go into the cookbook's `test/integration/default` directory
4. Then run `knife data bag create contrasthub creds --sercret-file encrypted_data_bag_secret` (this will require that your $EDITOR environment variable is set)
5. Add data bag items for your Contrast Hub username and password and save the file; for example:

```
"id": "creds",
"username": "brian.chau@contrastsecurity.com",
"password": "<your Contrast Hub password>"
```

For more information about using encrypted data bags and more, please watch this nice video: https://youtu.be/y4ZAVafd1RI.

## Running this cookbook
Please note that this cookbook can take some time to run and TeamServer will still not be ready until about 15-30 minutes after the cookbook execution is complete due to the delay associated with installing, configuring, and initializing TeamServer for the first time.  Please allocate 30-45 minutes for TeamServer to be up, running, and accessible.

TeamServer will be fully running and accessible when you see a log message like `...Contrast TeamServer Ready - Took 1047250ms` from the `/opt/contrast/logs/server.log` (on Linux) or `C:\Program Files\Contrast\logs\server.log` (on Windows).
