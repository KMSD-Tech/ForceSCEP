# ForceSCEP

# Summary
This PowerShell script is designed to manage the installation and verification of SCEP certificates on a device. It checks for the presence of a specific registry key and a SCEP certificate issued by a specified issuer. If the certificate is not present, it triggers an Intune sync and waits for the certificate to be installed. If the network authentication type is WPA2-Enterprise, it disconnects and reconnects to the current SSID. Finally, it sets a registry key to indicate that the process has been completed.

# README
SCEP Certificate Management Script
This script is used to manage the installation and verification of SCEP certificates on a device.  In an environment where you are utilizing EAP-TEAP, a device will be initially authenticated using the device certificate.  After the user certificate is installed, there is currently no method to switch to the user-certificate instead of the device-certificate.  This script facilitates that switchover.

I would recommend compiling this as an exe using something like ps2exe.  You should also probably sign the PowerShell script before compiling.  The only variable that needs to be set in the script is the issuer name for your CA

Once you have a compiled exe, just deploy it with something like this (this would make a scheduled task that runs for all users on logon):

`if exist "%programdata%\scripts" copy /y forcescep.exe "%programdata%\scripts"`

`schtasks /create /tn "Force SCEP Cert" /tr "%programdata%\scripts\forcescep.exe" /sc ONLOGON /rl HIGHEST /ru "BUILTIN\Users" /f`

# Features
Checks for the presence of a specific registry key.
Checks for the presence of a SCEP certificate issued by a specified issuer.
Triggers an Intune sync to install the SCEP certificate if it’s not present.
Disconnects and reconnects to the current SSID if the network authentication type is WPA2-Enterprise.
Sets a registry key to indicate that the process has been completed.

# Usage
Define the issuer name for your certificates at the beginning of the script.
Run the script on the device where you want to manage the SCEP certificate.

# Requirements
PowerShell 5.1 or later
Network access
Intune Management Extension

# Note
This script is intended to be run on a device where the Intune Management Extension is installed and the device has network access. It does not require administrative privileges.

Please ensure to test this script in a controlled environment before deploying it in a production environment. Always back up your data and configurations prior to running any script. Use at your own risk. The author will not be responsible for any misuse or damage caused by this script.

# License
This script is provided as-is with no warranties or guarantees. Use it at your own risk. You are free to modify and distribute it as long as you give credit to the original author.

# Author
Original script written by KMSD-Tech.

# Version
1.0 - Initial release
