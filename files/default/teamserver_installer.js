// This PhantomJS script will generate a command-line script that can be used to downlaod the target Contrast TeamServer installer.
// It does the following...
// 1. Authenticate to Contrast Hub with user-provided credentials
// 2. Browses to the "Downloads" page
// 3. Navigates the Downloads page DOM to extract the target installer's download URL
// 4. Produces the command-line script file used to execute a download (Bash script for Linux and PowerShell script for Windows)

var page = require('webpage').create(), // PhantomJS webpage module
    system = require('system'), // PhantomJS system module
    fs = require('fs'), // PhantomJS file system module
    username, // Contrast Hub username
    password, // Contrast Hub password
    target_os, // Target Contrast TeamServer installer's file name
    url1 = 'http://hub.contrastsecurity.com', // Contrast Hub URL
    url2 = 'https://hub.contrastsecurity.com/h/download/all/typed.html', // URL for Contrast Hub Downloads page
    target_installer, // Name of the file that is generated which contains the 'wget' command needed to download the target TeamServer installer (this was done because PhantomJS does not support file downloads)
    output_file = "";

// The following checks for the expected number of command-line arguments
if (system.args.length !== 5) {
    console.log('ERROR: Missing input arguments for ' + system.args[0] + '\n' + 'USAGE: teamserver_installer.js <Contast Hub username> <Contrast Hub password> <Target OS> <Target installer filename>')
    phantom.exit();
}

username = system.args[1].toString();
password = system.args[2].toString();
target_os = system.args[3].toString().toLowerCase();
target_installer = system.args[4].toString();

// PhantomJS event handler to ensure console.log outputs
page.onConsoleMessage = function(msg) {
    system.stderr.writeLine( 'console: ' + msg );
};

// PhantomJS event handler executed when DOM onLoadFinished occurs
page.onLoadFinished = function(status) {
    console.log("PhantomJS loaded page: " + page.url);
    // var filename = Date.now() + ".png"
    // page.render(filename);
}

// Find the target TeamServer installer based on its filename
function get_installer(target_installer, id) {
    // Navigate through the DOM to find the target installer based on its filename
    var trs = document.getElementById(id).getElementsByTagName("tr");
    var targetstr = target_installer;
    var currentstr = "";
    var str_match;
    var i,j,k;
    for (i = 0; i < trs.length; i++) {
        var tds = trs[i].getElementsByTagName("td");
        for (j = 0; j < tds.length; j++) {
            currentstr = tds[j].innerHTML;
            str_match = targetstr.localeCompare(currentstr);
            // If a match for the target installer filename is found, find the Download button element
            if(str_match === 0) {
                buttons = trs[i].getElementsByTagName("button");
                targetstr = "Download";
                for (k = 0; k < buttons.length; k++) {
                    currentstr = buttons[k].innerHTML;
                    str_match = targetstr.localeCompare(currentstr);
                    // If the target Download button is found, then extract the unique Expires, Signature, and Key-Pair-Id values need to execute a download of the installer
                    if(str_match === 0) {
                        var inputs = buttons[k].parentNode.getElementsByTagName("input");
                        var download_url = '"' + buttons[k].parentElement.action +
                                           '?Expires=' + inputs[0].value +
                                           '&Signature=' + inputs[1].value +
                                           '&Key-Pair-Id=' + inputs[2].value + '"';
                        return download_url;
                    }
                }
            }
        }
    }
}

setTimeout(function() {
    // Check if the target installer file matches the target OS
    // If the target installer file has a '.exe' extension, then the target OS must be Windows
    var installer_extension = target_installer.slice(-3);
    if((installer_extension.localeCompare("exe") === 0 && target_os.localeCompare("linux") === 0 || (installer_extension.localeCompare(".sh") === 0 && target_os.localeCompare("windows") === 0))) {
        console.log('ERROR: Target OS (' + target_os + ') cannot use the target TeamServer installer file (' + target_installer + ')');
        phantom.exit(1);
    } else {
        // Open Contrast Hub homepage
        page.open(url1, function(status) {
            if(status === "success") {
                // Login to Contrast Hub
                page.evaluate(function(username, password) {
                    document.getElementById("username").value = username;
                    document.getElementById("password").value = password;
                    document.getElementById("login").submit();
                }, username, password);
            } else {
                console.log('Failed to load' + url1);
                phantom.exit(1);
            }
        });
    }
}, 0);

// Wait 60 seconds before proceeding to allow the login to Hub to complete
setTimeout(function() {
    // Prepare output file that is a Bash (Linux) or PowerShell (Windows) script that can be executed to download the target TeamServer installer
    if(target_os.localeCompare("linux") === 0) { // Use wget for Linux
        output_file = "download_installer.sh";
        installer_file = "contrast_installer.sh";
        var output = "#!/bin/bash\n" +
                     "wget -O " + installer_file + " ";
    } else if(target_os.localeCompare("windows") === 0) { // Use Invoke-WebRequest (Powershell) for Windows
        output_file = "download_installer.ps1";
        installer_file = "contrast_installer.exe";
        var output = "Invoke-WebRequest -OutFile " + installer_file + " ";
    } else {
        console.log("Invalid target operating system.  Please specify either 'Linux' or 'Windows'.");
        phantom.exit(1);
    }

    page.open(url2, function(status) {
        if(status === "success") {
            // If the Contrast Hub Download page is successfully loaded, then find the target Contrast TeamServer installer
            var url = page.evaluate(function(target_installer, get_installer) {
                var download_url = get_installer(target_installer, "installer");
                if(download_url != null)
                    return download_url;
                else {
                    console.log("Failed to find target installer file.")
                    phantom.exit(1);
                }
            }, target_installer, get_installer);
            output += url + "\n";
            console.log("File output: " + output);
            fs.write(output_file, output);
            phantom.exit(0);
        } else { // Try to reach the Contrast Hub Download page again since it often does not load the first time when looged in as an Admin
            console.log('Failed to load ' + url2 + '. Trying again.');console.log("Initial status = " + status);
            page.open(url2, function(status) {
                if(status === "success") {
                    // If the Contrast Hub Download page is successfully loaded, then find the target Contrast TeamServer installer
                    var url = page.evaluate(function(target_installer, get_installer) {
                        var download_url = get_installer(target_installer, "installer");
                        if(download_url != null)
                            return download_url;
                        else {
                            console.log("Failed to find target installer file.")
                            phantom.exit(1);
                        }
                    }, target_installer, get_installer);
                    output += url + "\n";
                    console.log("File output: " + output);
                    fs.write(output_file, output);
                    phantom.exit(0);
                } else {
                    console.log("Second attempt to load Downloads page has failed.");
                    phantom.exit(1);
                }
            });
        }
    });
}, 60000);