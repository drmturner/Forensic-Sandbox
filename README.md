# Auto-configure Windows Sandbox for Forensic Analysis
Auto-configuration for a custom instance of Windows Sandbox. Auto-launches after removable media storage detection. 

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
   - Optical Media Watcher.xml
     - Description: This is an XML file that defines a Task Scheduler task. It monitors for optical media data mounting.
     - Purpose: To automate logging when optical drives are initialized and media are loaded. Launches at user login. 
   - opticalwatcher.ps1
     - Description: A PowerShell script that handles operations related to logging optical media.
     - Purpose: Writes to the event log when optical media is loaded to Event ID 2001. Runs continuously in the background.
   - Update and Launch Sandbox on USB Insertion.xml
     - Description: An XML file designed for Task Scheduler that updates and launches the Windows Sandbox feature upon optical media or USB media insertion.
     - Purpose: Automates the process of starting a secure sandbox environment whenever a USB device is connected, enhancing system security.
   - updatelogwritelocation.ps1
     - Description: A PowerShell script to launch and configure a custom Sandbox environment.
     - Purpose: Displays GUI to the user as it runs through detection and configuration of the Windows Sandbox based upon the media loaded and/or selected.

## Additional Features
Debug Logging: Both scripts provide detailed logging to a file (OpticalMediaSetup.log) located in the system’s temporary directory (%Temp%). Logs include timestamps for all operations and error messages for troubleshooting.

## Use Cases

### Current Use Cases
- Automating the initial setup of systems to enable Windows Sandbox.
- Streamlining the configuration of custom event logging and task scheduling.
- Forensics for Police

### Potential Use Cases
- Anything that requires JIT admin access in an isolated environment
- Malware Forensics


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
