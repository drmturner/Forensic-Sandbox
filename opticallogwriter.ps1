# Initialize variables
$driveStates = @{}
$driveLetters = @()
$VerbosePreference = "Continue"
$ErrorActionPreference = "SilentlyContinue"
# Ensure the event log and source are registered
if (-not (Get-EventLog -List | Where-Object { $_.Log -eq "OpticalMediaLog" })) {
   New-EventLog -LogName "OpticalMediaLog" -Source "OpticalMediaSource"
}
while ($true) {
   try {
       $cdDrives = Get-CimInstance -Class Win32_CDROMDrive
       $currentDriveLetters = $cdDrives.Drive
       # Detect new drives (Drive Initialization)
       $newDrives = $currentDriveLetters | Where-Object { $_ -notin $driveLetters }
       if ($newDrives) {
           foreach ($newDrive in $newDrives) {
               Write-Verbose "New drive detected: $newDrive"
               # Write event log entry for drive initialization (Event ID 2000)
               try {
                   Write-EventLog -LogName "OpticalMediaLog" -Source "OpticalMediaSource" -EventId 2000 -EntryType Information -Message "Drive initialized: $newDrive"
                   Write-Verbose "Event log entry written for drive initialization: $newDrive"
               } catch {
                   Write-Error "Failed to write event log: $_"
               }
               # Initialize drive state
               $mediaLoaded = ($cdDrives | Where-Object { $_.Drive -eq $newDrive }).MediaLoaded
               $driveStates[$newDrive] = $mediaLoaded
               Write-Verbose "Initializing state for drive $newDrive : MediaLoaded = $mediaLoaded"
               # If media is already loaded, log media insertion
               if ($mediaLoaded -eq $true) {
                   Write-Verbose "Media is already loaded in new drive $newDrive"
                   # Write event log entry for media insertion (Event ID 2001)
                   try {
                       Write-EventLog -LogName "OpticalMediaLog" -Source "OpticalMediaSource" -EventId 2001 -EntryType Information -Message "Media inserted in drive $newDrive"
                       Write-Verbose "Event log entry written for media insertion in drive $newDrive"
                   } catch {
                       Write-Error "Failed to write event log: $_"
                   }
               }
           }
           # Update drive letters
           $driveLetters += $newDrives
       }
       # Detect removed drives
       $removedDrives = $driveLetters | Where-Object { $_ -notin $currentDriveLetters }
       if ($removedDrives) {
           foreach ($removedDrive in $removedDrives) {
               Write-Verbose "Drive letter removed: $removedDrive"
               # Remove from driveLetters and driveStates
               $driveLetters = $driveLetters | Where-Object { $_ -ne $removedDrive }
               if ($driveStates.ContainsKey($removedDrive)) {
                   # If media was loaded before removal, log media removal
                   if ($driveStates[$removedDrive] -eq $true) {
                       Write-Verbose "Media was loaded in drive $removedDrive before it was removed"
                       # Write event log entry for media removal (Event ID 2002)
                       try {
                           Write-EventLog -LogName "OpticalMediaLog" -Source "OpticalMediaSource" -EventId 2002 -EntryType Information -Message "Media removed from drive $removedDrive"
                           Write-Verbose "Event log entry written for media removal in drive $removedDrive"
                       } catch {
                           Write-Error "Failed to write event log: $_"
                       }
                   }
                   $driveStates.Remove($removedDrive) | Out-Null
               }
           }
       }
       # Process current drives
       foreach ($drive in $cdDrives) {
           $driveLetter = $drive.Drive
           $mediaLoaded = $drive.MediaLoaded
           Write-Verbose "Drive: $driveLetter, MediaLoaded: $mediaLoaded"
           if ($driveStates.ContainsKey($driveLetter)) {
               $prevMediaLoaded = $driveStates[$driveLetter]
               if ($prevMediaLoaded -ne $mediaLoaded) {
                   if ($mediaLoaded -eq $true) {
                       # Media has been inserted
                       Write-Verbose "Media inserted in drive $driveLetter"
                       # Write event log entry for media insertion (Event ID 2001)
                       try {
                           Write-EventLog -LogName "OpticalMediaLog" -Source "OpticalMediaSource" -EventId 2001 -EntryType Information -Message "Media inserted in drive $driveLetter"
                           Write-Verbose "Event log entry written for media insertion in drive $driveLetter"
                       } catch {
                           Write-Error "Failed to write event log: $_"
                       }
                   } else {
                       # Media has been removed
                       Write-Verbose "Media removed from drive $driveLetter"
                       # Write event log entry for media removal (Event ID 2002)
                       try {
                           Write-EventLog -LogName "OpticalMediaLog" -Source "OpticalMediaSource" -EventId 2002 -EntryType Information -Message "Media removed from drive $driveLetter"
                           Write-Verbose "Event log entry written for media removal in drive $driveLetter"
                       } catch {
                           Write-Error "Failed to write event log: $_"
                       }
                   }
                   # Update the drive state
                   $driveStates[$driveLetter] = $mediaLoaded
               }
           } else {
               # Initialize drive state if not present (should not happen)
               $driveStates[$driveLetter] = $mediaLoaded
               Write-Verbose "Initializing state for drive $driveLetter : MediaLoaded = $mediaLoaded"
           }
       }
   } catch {
       Write-Error "An error occurred: $_"
   }
   Start-Sleep -Seconds 5
}
