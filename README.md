# Auto-configure Windows Sandbox for Forensic Analysis
Auto-configuration for a custom instance of Windows Sandbox. Auto-launches after removable media storage detection. This is an independent project not associated with any organization. Any similarity is coincidental or unavoidable due to the nature of script commands. 

**Overview**

This repository contains scripts and related resources to automate the initial setup of systems that require enabling Windows Sandbox, creating custom event logs, and scheduling tasks using XML files. The project is licensed under the Apache License 2.0.

## Files

1. Enable-Dependencies.ps1
   - A PowerShell script designed to perform initial setup tasks, including:
     - Checking for administrative privileges.
     - Creating a custom event log (OpticalMediaLog).
     - Enabling Windows Sandbox (Containers-DisposableClientVM) feature.
     - Loading tasks into the Windows Task Scheduler from XML files.
     - Prompting for a reboot after completion.
   - Execute this script as an administrator to configure the system for optical media dependencies and task automation.

2. Sandbox Files:
   - OpticalMedialogger.xml
     - Description: This is an XML file that defines a Task Scheduler task. It monitors for optical media data mounting and launches the opticalwritelog.ps1 files.
     - Purpose: To automate logging when optical drives are initialized and media are loaded. Launches at user login. 
   - opticalwritelog.ps1
     - Description: A PowerShell script that handles operations related to logging optical media.
     - Purpose: Writes to the event log when optical media is loaded to Event ID 2001. Runs continuously in the background.
   - Start Sandbox.xml
     - Description: An XML file designed for Task Scheduler that launches sandboxconfig.ps1 when event code 2001 (new optical storage media) or 2003 (new USB storage media).
     - Purpose: Automates the process of starting a secure sandbox environment whenever a USB device or optical media is loaded.
   - sandboxconfig.ps1
     - Description: A PowerShell script to launch and configure a custom Sandbox environment.
     - Purpose: Displays GUI to the user as it runs through detection and configuration of the Windows Sandbox based upon the media loaded and/or selected. Requires no user interaction unless multiple drives are detected. Ignores the System Root Drive

## Additional Features
Debug Logging: Both scripts provide detailed logging to a file (DependencySetup.log and SandboxErrors-[timestamp].log) located in the Sandbox directory. Logs include timestamps for all operations and error messages for troubleshooting.

## Use Cases

### Current Use Cases
- Forensics for Police
- Anything that requires JIT admin access in an isolated environment
- Malware Forensics for security teams


## Installation
### Prerequisites
- Administrator Privileges: The scripts require administrative rights to perform system-level changes.
- Virtualization Support: Windows Sandbox requires virtualization to be enabled in the system BIOS.

### Steps
1. Download the Repository:
Clone or download this repository to your local machine:
```
git clone https://github.com/drmturner/autorunsandbox.git
```

2. Save Sandbox Files:
Save the Sandbox Files to _C:\Sandbox_

3. Run the Script:
Open a PowerShell terminal as Administrator and run the script:
``` powershell
.\Enable-Dependencies.ps1
```
Follow any on-screen prompts to complete the setup.

4. Reboot the System:
After the script completes, reboot the machine for the changes to take effect.

## Contribution
Contributions are welcome! Please submit a pull request or open an issue to report bugs or suggest enhancements.

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](/LICENSE) file for details.
Feel free to adjust the content further to fit your preferences. Let me know if you’d like additional changes or enhancements!
