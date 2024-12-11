Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Add-Type -AssemblyName System.Windows.Forms
# Initialize a log file for debugging
$logFile = "$env:SystemDrive\Sandbox\DependencySetup.log"
Function Output-Progress {
   param ([string]$message)
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   Add-Content -Path $logFile -Value "[$timestamp] $message"
}
Output-Progress "Script started."
# Ensure the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   Output-Progress "The script is not running as Administrator."
   [System.Windows.Forms.MessageBox]::Show("This script must be run as Administrator. Please restart it with administrative privileges.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
   exit
}
# Create a custom event log
Output-Progress "Creating custom event log..."
try {
   if (-not (Get-EventLog -LogName "OpticalMediaStateChange" -ErrorAction SilentlyContinue)) {
       New-EventLog -LogName "OpticalMediaStateChange" -Source "OpticalMediaSource"
       Output-Progress "Event log 'OpticalMediaStateChange' created successfully."
   } else {
       Output-Progress "Event log 'OpticalMediaStateChange' already exists."
   }
} catch {
   Output-Progress "Error creating event log: $_"
}
# Enable Windows Sandbox feature
Output-Progress "Enabling DisposableClientVM feature..."
try {
   Enable-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -All -Online -NoRestart
   Output-Progress "Sandbox feature enabled successfully."
} catch {
   Output-Progress "Error enabling DisposableClientVM: $_"
   [System.Windows.Forms.MessageBox]::Show("Failed to enable DisposableClientVM feature. Ensure virtualization is enabled in the BIOS.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
   exit
}
# Load XML files into Task Scheduler
Output-Progress "Loading tasks into Task Scheduler..."
$xmlFilesPath = "C:\Sandbox" 
try {
   if (Test-Path $xmlFilesPath) {
       Get-ChildItem -Path $xmlFilesPath -Filter "*.xml" | ForEach-Object {
           $taskName = $_.BaseName
           schtasks.exe /Create /XML $_.FullName /TN $taskName | Out-Null
           Output-Progress "Task '$taskName' loaded successfully."
       }
   } else {
       Output-Progress "XML files directory not found."
       [System.Windows.Forms.MessageBox]::Show("XML files directory not found at $xmlFilesPath.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
       exit
   }
} catch {
   Output-Progress "Error loading tasks: $_"
}
# Prompt for reboot
Output-Progress "Prompting user for reboot..."
$result = [System.Windows.Forms.MessageBox]::Show("Setup complete. Click OK to reboot and apply changes.", "Reboot Required", [System.Windows.Forms.MessageBoxButtons]::OKCancel)
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
   Output-Progress "User confirmed reboot. Rebooting now..."
   Restart-Computer -Force
} else {
   Output-Progress "User canceled the reboot."
   [System.Windows.Forms.MessageBox]::Show("Please reboot the machine manually to apply changes. Changes will not be applied and feature will not be usable until a reboot completes.", "Reboot Canceled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}
Output-Progress "Script finished."
