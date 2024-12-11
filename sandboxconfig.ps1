# Ensure STA mode
[System.Threading.Thread]::CurrentThread.ApartmentState = 'STA'

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set ErrorActionPreference to stop on errors
$ErrorActionPreference = 'SilentlyContinue'

# Set up logging
$sandboxDir = "$env:SystemDrive\Sandbox"
$logDir = Join-Path -Path $sandboxDir -ChildPath "Logs"
if (!(Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$timestampForFile = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path -Path $logDir -ChildPath "SandboxErrors-$timestampForFile.log"

# Function to log errors
function Log-Error {
    param(
        [string]$errorName,
        [string]$errorMessage
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp - $errorName - $errorMessage"
    # Write to console
    Write-Error $logEntry
    # Append to log file
    Add-Content -Path $logFile -Value $logEntry
}

# Picture Box Specifications
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.SizeMode = "Zoom"
$pictureBox.Location = New-Object System.Drawing.Point(10,10)
$pictureBox.Size = New-Object System.Drawing.Size(80,80)

# Specify the path of the Image
$logoPath = "\\path\to\company\logo.jpg"

# Create the form and controls
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Sandbox Setup"
$form.Width = 400
$form.Height = 300
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.ControlBox = $false  # Disable the close button

try {
   $pictureBox.Image = [System.Drawing.Image]::FromFile($logoPath)
} catch {
   # Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
   # Fallback to using the icon from Windows Sandbox
   try {
       $sandboxPath = "$env:windir\System32\WindowsSandbox.exe"
       if (Test-Path $sandboxPath) {
           $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($sandboxPath)
           $pictureBox.Image = $icon.ToBitmap()
       } else {
           Log-Error -errorName "FileNotFound" -errorMessage "Windows Sandbox executable not found at $sandboxPath. Please run Enable-Dependecies.ps1 to enable the feature."
       }
   } catch {
       Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
   }
}
# Sandbox Message Popup
$sandboxMessage = "This is a temporary environment. Please save any files that need to be kept in the Evidence folder on the desktop."
$messageCommand = "powershell.exe -WindowStyle Hidden -Command ""Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('$sandboxMessage', 'Notice', 'OK', 'Information')"""

# Create the Descriptor to explain
$descriptor = New-Object System.Windows.Forms.Label
$descriptor.Location = New-Object System.Drawing.Point(100,10)
$descriptor.Size = New-Object System.Drawing.Size(280,30)
$descriptor.Text = "Please standby while we get you set up!"

# Create the label to show the current step
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(100,50)
$label.Size = New-Object System.Drawing.Size(280,30)
$label.Text = "Initializing..."

# Create the progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(100,90)
$progressBar.Size = New-Object System.Drawing.Size(280,30)
$progressBar.Style = "Continuous"
$progressBar.Minimum = 0
$progressBar.Maximum = 1000  # Use a scale of 0 to 1000 to handle decimal percentages
$progressBar.Value = 0

# Create dropdown and submit button for drive selection, but set them invisible initially
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(100,130)
$comboBox.Size = New-Object System.Drawing.Size(200,30)
$comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBox.Visible = $false

$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Submit"
$submitButton.Location = New-Object System.Drawing.Point(310, 130)
$submitButton.Size = New-Object System.Drawing.Size(75, 30)
$submitButton.Enabled = $false  # Disable the button initially
$submitButton.Visible = $false

# Add controls to the form
$form.Controls.Add($pictureBox)
$form.Controls.Add($descriptor)
$form.Controls.Add($label)
$form.Controls.Add($progressBar)
$form.Controls.Add($comboBox)
$form.Controls.Add($submitButton)

# Declare $driveLabels at the top level
$driveLabels = @{}

# Function to update the progress bar and label
function Update-ProgressBar {
    param(
        [int]$value,
        [string]$message = ""
    )
    if ($value -lt $progressBar.Minimum) { $value = $progressBar.Minimum }
    if ($value -gt $progressBar.Maximum) { $value = $progressBar.Maximum }
    $progressBar.Value = $value
    if ($message -ne "") {
        $label.Text = $message
    }
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to get drive labels
function Get-DriveLabels {
    param([ref]$driveLabels)
    $driveLabels.Value = @{}

    try {
        # Detect USB drives
        $usbDrives = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" }
        foreach ($drive in $usbDrives) {
            $partitions = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            foreach ($partition in $partitions) {
                $logicalDisks = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                foreach ($disk in $logicalDisks) {
                    $driveLetter = $disk.DeviceID
                    # Ensure drive letter ends with backslash
                    if (-not $driveLetter.EndsWith('\')) {
                        $driveLetter += '\'
                    }
                    $volume = Get-CimInstance -ClassName Win32_Volume | Where-Object { $_.DriveLetter -eq $driveLetter.TrimEnd('\') }
                    $volumeLabel = if ($volume.Label) { $volume.Label } else { "Unknown" }
                    $capacityGB = [math]::Round($volume.Capacity / 1GB, 2)
                    $driveLabels.Value["[USB] $driveLetter $volumeLabel [$capacityGB GB]"] = @{ DriveLetter = $driveLetter; Type = "USB" }
                }
            }
        }

        # Detect CD/DVD drives with media loaded
        $cdDrives = Get-CimInstance -ClassName Win32_CDROMDrive | Where-Object { $_.MediaLoaded -eq $true }
        foreach ($cdDrive in $cdDrives) {
            $driveLetter = $cdDrive.Drive
            # Ensure drive letter ends with backslash
            if (-not $driveLetter.EndsWith('\')) {
                $driveLetter += '\'
            }
            $volumeLabel = if ($cdDrive.VolumeName) { $cdDrive.VolumeName } else { "Unknown" }
            $driveLabels.Value["[CD/DVD] $driveLetter $volumeLabel"] = @{ DriveLetter = $driveLetter; Type = "CD" }
        }
    } catch {
        Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
    }
}

# Event handler for form load to start processing after form is displayed
$form.Add_Shown({
    try {
        # Perform drive detection
        Update-ProgressBar -value 50 -message "Detecting drives..."

        # Get drive labels
        Get-DriveLabels -driveLabels ([ref]$driveLabels)

        # Update progress bar
        Update-ProgressBar -value 100 -message "Drive detection complete."

        # Brief pause to show completion
        Start-Sleep -Milliseconds 500

        # Proceed based on the number of detected drives
        if ($driveLabels.Count -eq 0) {
            # No drives detected, show error message
            [System.Windows.Forms.MessageBox]::Show("No CD/DVD or USB drives detected.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            Log-Error -errorName "DriveDetectionError" -errorMessage "No CD/DVD or USB drives detected."
            $form.Close()
            exit
        }
        elseif ($driveLabels.Count -eq 1) {
            # Only one drive detected
            $selectedDriveKey = $driveLabels.Keys[0]
            $selectedDrive = $driveLabels[$selectedDriveKey]
            $driveLetter = $selectedDrive.DriveLetter
            $driveType = $selectedDrive.Type

            # Update descriptor and label
            $descriptor.Text = "One drive detected."
            $label.Text = "Preparing to launch Sandbox..."

            # Proceed to create the sandbox configuration
            Start-SandboxProcess -DriveLetter $driveLetter -DriveType $driveType
        } else {
            # Multiple drives detected
            # Update descriptor and label
            $descriptor.Text = "Please select a drive and click Submit."
            $label.Text = ""

            # Populate the ComboBox
            $comboBox.Items.Clear()
            $driveLabels.Keys | ForEach-Object { $comboBox.Items.Add($_) }
            $comboBox.SelectedIndex = -1  # No default selection

            # Show the ComboBox and Submit button
            $comboBox.Visible = $true
            $submitButton.Visible = $true

            # Corrected Event Handler for ComboBox selection change
            $comboBox.add_SelectedIndexChanged({
                param($sender, $e)
                if ($comboBox.SelectedIndex -ge 0) {
                    $submitButton.Enabled = $true  # Enable the button when a selection is made
                } else {
                    $submitButton.Enabled = $false
                }
            })

            # Corrected Event Handler for Submit button click
            $submitButton.add_Click({
                param($sender, $e)
                try {
                    $selectedDriveKey = $comboBox.SelectedItem
                    $selectedDrive = $driveLabels[$selectedDriveKey]
                    $driveLetter = $selectedDrive.DriveLetter
                    $driveType = $selectedDrive.Type

                    # Update descriptor and label
                    $descriptor.Text = "Preparing to launch Sandbox..."
                    $label.Text = ""

                    # Remove the ComboBox and Submit button from the form
                    $comboBox.Visible = $false
                    $submitButton.Visible = $false
                    [System.Windows.Forms.Application]::DoEvents()

                    # Proceed to create the sandbox configuration
                    Start-SandboxProcess -DriveLetter $driveLetter -DriveType $driveType
                } catch {
                    Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
                }
            })
        }
    } catch {
        Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
    }
})

# Function to start the sandbox process
function Start-SandboxProcess {
    param(
        [string]$DriveLetter,
        [string]$DriveType
    )

    try {
        $sandboxDir = "$env:SystemDrive\Sandbox"
        $sandboxPath = Join-Path -Path $sandboxDir -ChildPath "SandboxConfig.wsb"

        if (!(Test-Path -Path $sandboxDir)) {
            New-Item -ItemType Directory -Path $sandboxDir -Force | Out-Null
        }
        # Define the Evidence folder paths
        $evidenceHostFolder = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\Forensic Evidence"
        $evidenceSandboxFolder = "C:\Users\WDAGUtilityAccount\Desktop\Evidence"
        # Ensure the Evidence folder exists on the host
        if (!(Test-Path -Path $evidenceHostFolder)) {
            New-Item -ItemType Directory -Path $evidenceHostFolder -Force | Out-Null
        }
        if ($DriveType -eq "CD") {
            # Copy CD contents
            $cdContentPath = Join-Path -Path $sandboxDir -ChildPath "CDTemp"
            if (!(Test-Path -Path $cdContentPath)) {
                New-Item -ItemType Directory -Path $cdContentPath -Force | Out-Null
            } else {
                # Clear existing contents
                Remove-Item -Path "$cdContentPath\*" -Recurse -Force
            }

            # Get total size of data to copy
            $totalSize = (Get-ChildItem -Path $DriveLetter -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $copiedSize = 0

            # Copy files with progress
            function Copy-WithProgress {
                param (
                    [string]$Source,
                    [string]$Destination
                )
                try {
                    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
                        try {
                            $sourceFile = $_.FullName
                            $relativePath = $sourceFile.Substring($Source.Length)
                            $destFile = Join-Path $Destination $relativePath

                            # Ensure destination directory exists
                            $destDir = Split-Path $destFile
                            if (!(Test-Path -Path $destDir)) {
                                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                            }

                            # Copy the file
                            Copy-Item -Path $sourceFile -Destination $destFile -Force

                            # Update copied size
                            $copiedSize += $_.Length
                            # Calculate progress percentage
                            $progressPercentage = ($copiedSize / $totalSize) * 100
                            $progressPercentageRounded = "{0:N2}" -f $progressPercentage

                            # Update progress bar and message
                            # We allocate 500 to 900 range for copying progress (40% of the progress bar)
                            $progressBarValue = 500 + ($progressPercentage * 4)
                            Update-ProgressBar -value $progressBarValue -message "Copying CD contents... $progressPercentageRounded% completed"
                        } catch {
                            Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
                        }
                    }
                } catch {
                    Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
                }
            }

            # Start copying
            Copy-WithProgress -Source $DriveLetter -Destination $cdContentPath

            Update-ProgressBar -value 950 -message "CD contents copied."

            # Ensure paths are properly escaped for XML
            $hostFolderPath = [System.Security.SecurityElement]::Escape($cdContentPath)
            $sandboxFolderPath = "C:\Users\WDAGUtilityAccount\Desktop\CDContent"
            # Escape Evidence folder path for XML
            $evidenceHostFolderEscaped = [System.Security.SecurityElement]::Escape($evidenceHostFolder)
            $evidenceSandboxFolderEscaped = [System.Security.SecurityElement]::Escape($evidenceSandboxFolder)
            # Create the sandbox configuration
            $wsbContent = @"
<Configuration>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>$hostFolderPath</HostFolder>
            <SandboxFolder>$sandboxFolderPath</SandboxFolder>
            <ReadOnly>true</ReadOnly>
        </MappedFolder>
        <MappedFolder>
            <HostFolder>$evidenceHostFolderEscaped</HostFolder>
                <SandboxFolder>$evidenceSandboxFolderEscaped</SandboxFolder>
                <ReadOnly>false</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <Networking>Disable</Networking>
    <AudioInput>Disable</AudioInput>
    <VideoInput>Disable</VideoInput>
    <ProtectedClient>Enable</ProtectedClient>
    <PrinterRedirection>Disable</PrinterRedirection>
    <ClipboardRedirection>Disable</ClipboardRedirection>
    <LogonCommand>
        <command>$messagecommand</command>
    </LogonCommand>
</Configuration>
"@
            $wsbContent | Out-File -FilePath $sandboxPath -Force -Encoding UTF8
            Update-ProgressBar -value 1000 -message "Launching Sandbox..."
            # Close form and launch Sandbox
            $form.Close()
            Start-Process -FilePath "$env:windir\System32\WindowsSandbox.exe" -ArgumentList $sandboxPath
            # Wait for Sandbox to close before cleanup
            while (Get-Process -Name WindowsSandbox -ErrorAction SilentlyContinue) {
                Start-Sleep -Seconds 1
            }
            # Cleanup CDTemp folder
            Remove-Item -Path "$cdContentPath\*" -Recurse -Force
            # After sandbox closes, open the Evidence folder on the host
            if (Test-Path -Path $evidenceHostFolder) {
               Start-Process -FilePath explorer.exe -ArgumentList "`"$evidenceHostFolder`""
            }

        } else {
            # For USB drives, map directly

            # Ensure paths are properly escaped for XML
            $hostFolderPath = [System.Security.SecurityElement]::Escape($DriveLetter.TrimEnd('\'))
            $sandboxFolderPath = "C:\Users\WDAGUtilityAccount\Desktop\USBContent"
            # Escape Evidence folder path for XML
            $evidenceHostFolderEscaped = [System.Security.SecurityElement]::Escape($evidenceHostFolder)
            $evidenceSandboxFolderEscaped = [System.Security.SecurityElement]::Escape($evidenceSandboxFolder)

            # Create the sandbox configuration
            $wsbContent = @"
<Configuration>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>$hostFolderPath</HostFolder>
            <SandboxFolder>$sandboxFolderPath</SandboxFolder>
            <ReadOnly>true</ReadOnly>
        </MappedFolder>
        <MappedFolder>
            <HostFolder>$evidenceHostFolderEscaped</HostFolder>
            <SandboxFolder>$evidenceSandboxFolderEscaped</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <Networking>Disable</Networking>
    <AudioInput>Disable</AudioInput>
    <VideoInput>Disable</VideoInput>
    <ProtectedClient>Enable</ProtectedClient>
    <PrinterRedirection>Disable</PrinterRedirection>
    <ClipboardRedirection>Disable</ClipboardRedirection>
    <LogonCommand>
        <command>$messagecommand</command>
    </LogonCommand>
</Configuration>
"@
            $wsbContent | Out-File -FilePath $sandboxPath -Force -Encoding UTF8

            Update-ProgressBar -value 1000 -message "Launching Sandbox..."

            # Close form and launch Sandbox
            $form.Close()
            Start-Process -FilePath "$env:windir\System32\WindowsSandbox.exe" -ArgumentList $sandboxPath
            # Wait for Sandbox to close before cleanup
            while (Get-Process -Name WindowsSandbox -ErrorAction SilentlyContinue) {
                Start-Sleep -Seconds 1
            }
            # After sandbox closes, open the Evidence folder on the host
            if (Test-Path -Path $evidenceHostFolder) {
               Start-Process -FilePath explorer.exe -ArgumentList "`"$evidenceHostFolder`""
            }
        }
    } catch {
        Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
    }
}

# Show the form modally
try {
    $form.ShowDialog()
} catch {
    Log-Error -errorName $_.Exception.GetType().FullName -errorMessage $_.Exception.Message
}
