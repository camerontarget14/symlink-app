# Function to prompt for action using PowerShell
function Prompt-ForAction {
    $actionList = @("Create Symlinks", "Transfer Shot", "Archive Show", "Visit Documentation Site")
    $chosenAction = $null
    $chosenAction = $actionList | Out-GridView -Title "What would you like to do?" -OutputMode Single
    if (-not $chosenAction) {
        return "CANCELLED"
    }
    return $chosenAction
}

# Function to prompt for input using PowerShell
function Prompt-ForInput {
    param (
        [string]$Prompt,
        [string]$DefaultAnswer
    )
    $userInput = $null
    $userInput = Read-Host -Prompt $Prompt
    if (-not $userInput) {
        return "CANCELLED"
    }
    return $userInput
}

# Function to prompt for category selection using PowerShell
function Prompt-ForCategory {
    $categoryList = @("Film", "Series", "Music", "Commercial")
    $chosenCategory = $null
    $chosenCategory = $categoryList | Out-GridView -Title "Select a category:" -OutputMode Single
    if (-not $chosenCategory) {
        return "CANCELLED"
    }
    return $chosenCategory
}

# Function to show a popup message using PowerShell
function Show-Popup {
    param (
        [string]$Message
    )
    [System.Windows.MessageBox]::Show($Message)
}

# Function to open the documentation site
function Open-DocumentationSite {
    Start-Process "https://www.wearebaked.com"
}

# Function to execute robocopy command in a new terminal window
function Execute-Robocopy {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", "robocopy `"$SourcePath`" `"$DestinationPath`" /E /Z /XA:H"
}

# Prompt for action
$action = Prompt-ForAction
if ($action -eq "CANCELLED") {
    Write-Host "Operation cancelled by the user."
    exit 0
}

switch ($action) {
    "Create Symlinks" {
        # Continue with current script for creating symlinks
    }
    "Transfer Shot" {
        Write-Host "Transfer Shot selected. Exiting for now."
        exit 0
    }
    "Archive Show" {
        # Prompt for project name and category
        $projectName = Prompt-ForInput -Prompt "Enter the project name:" -DefaultAnswer ""
        if ($projectName -eq "CANCELLED") {
            Write-Host "Operation cancelled by the user at project name prompt."
            exit 0
        }

        $category = Prompt-ForCategory
        if ($category -eq "CANCELLED") {
            Write-Host "Operation cancelled by the user at category selection."
            exit 0
        }

        # Ensure the project name and category are not empty
        if ([string]::IsNullOrEmpty($projectName) -or [string]::IsNullOrEmpty($category)) {
            Write-Host "Project name or category cannot be empty."
            exit 0
        }

        # Define source and destination paths
        $sourcePath = "Z:\$category\$projectName\SUITE\2_WORK\1_SEQUENCES\VFX"
        $destinationPath = "P:\$category\$projectName\BASKET\2_WORK\1_SEQUENCES\"

        # Execute robocopy command
        Execute-Robocopy -SourcePath $sourcePath -DestinationPath $destinationPath
        exit 0
    }
    "Visit Documentation Site" {
        Open-DocumentationSite
        exit 0
    }
    default {
        Write-Host "Unknown action. Exiting."
        exit 0
    }
}

# Prompt for project name and category for Create Symlinks option
$projectName = Prompt-ForInput -Prompt "Enter the project name:" -DefaultAnswer ""
if ($projectName -eq "CANCELLED") {
    Write-Host "Operation cancelled by the user at project name prompt."
    exit 0
}

$category = Prompt-ForCategory
if ($category -eq "CANCELLED") {
    Write-Host "Operation cancelled by the user at category selection."
    exit 0
}

# Ensure the project name and category are not empty
if ([string]::IsNullOrEmpty($projectName) -or [string]::IsNullOrEmpty($category)) {
    Write-Host "Project name or category cannot be empty."
    exit 0
}

# Create the project directory
$basePath = "C:\BAKED"
$projectPath = "$basePath\$category\$projectName"
$logPath = "$basePath\symlink_creation_log.txt"

New-Item -Path $projectPath -ItemType Directory -Force

# Create symbolic links
function Log-Message {
    param (
        [string]$Message
    )
    Add-Content -Path $logPath -Value $Message
}

function Create-Symlink {
    param (
        [string]$Target,
        [string]$Link
    )
    if (Test-Path -Path $Link -PathType Leaf) {
        Log-Message "Symlink at $Link already exists. Skipping creation."
    } elseif (Test-Path -Path $Target -PathType Container) {
        cmd /c mklink /D $Link $Target
        Log-Message "Created symlink at $Link pointing to $Target"
    } else {
        Log-Message "$Target is unreachable. Symlink not created."
        Show-Popup "$Target is unreachable. If you're connected to this storage location and are still seeing this error, the project has not yet been created at this location. Otherwise, you can ignore this."
    }
}

Create-Symlink -Target "Z:\$category\$projectName" -Link "$projectPath\SUITE"
Create-Symlink -Target "P:\$category\$projectName" -Link "$projectPath\BASKET"

Write-Host "Project directory and symbolic links created successfully."
exit 0
