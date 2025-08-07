<#
.SYNOPSIS
    Installs the latest version of Winget and its dependencies.

.DESCRIPTION
    This script automates the installation of Winget (Windows Package Manager) and its required dependencies.
    It handles downloading necessary files, installing dependencies, and managing potential errors during the process.

.NOTES
    File Name      : Install-WinGet.ps1
    Prerequisite   : Windows PowerShell 5.1
    Copyright 2023 : Kevin Kaminski

.EXAMPLE
    .\Install-WinGet.ps1
#>

# Do not use with PowerShell 7 or later, as this script is designed for Windows PowerShell 5.1.

# Suppress progress bars for faster execution
$progressPreference = 'silentlyContinue'

# Set the log path to the environment variable for the root of the temp folder
$LogPath = $env:TEMP

# Initialize status variable to track overall success of the installation
$overallStatus = $true

# Set the dependencies
$UIXAMLDependency = "Microsoft.UI.Xaml"
$UIXAMLAPPXDependency = $env:ProgramFiles + "\PackageManagement\NuGet\Packages\Microsoft.UI.Xaml.2.7.0\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"
$VCDependency = "Microsoft.VCLibs.x64.14.00.Desktop.appx"

# Function to log messages with timestamps
function Write-LogMessage {
    param([string]$Message)
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] $Message"
}

# Begin recording all interactions to the log file
Start-Transcript -Path "$LogPath\wingetinstall.log"

# Configure download location for Winget
$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]

# Download Microsoft binaries.
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Downloading winget to current directory..."
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx

# Workaround for Microsoft.UI.Xaml dependency.
# Creates an additional dependency on Microsoft.Web.Webview2
# Detection logic was breaking the silent install. Just installing NuGet's package provider.

Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Install Nuget..."
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host "NuGet provider not found. Installing..."
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -Confirm:$false
} else {
    Write-Host "NuGet provider is already installed."
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] NuGet provider is already installed."
}

# Install Winget PowerShell Module
# Check if Nuget Module is installed
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Checking for Nuget Powershell Module..."
if(-not (Get-Module -ListAvailable -Name NuGet)) {
    # Install the Nuget PowerShell Module
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Nuget Powershell Module not found. Installing..."
    Install-Module -Name NuGet -Force
}
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Nuget Powershell Module found."

# Configure Nuget.org repository
# Check if Nuget.org repository is registered
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Check if Nuget.org repository is registered..."
if(-not (Get-PackageSource | Where-Object { $_.Name -eq 'nuget.org' })) 
{
    # Register the Nuget.org repository
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Nuget.org repository not found. Registering..."
    Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet
}
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Nuget.org repository found."

# Install Microsoft.UI.Xaml
# Check if UI Xaml is installed
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Checking for Microsoft UI XAML..."
if (-not (Get-Package -Name $UIXAMLDependency -RequiredVersion 2.7 -ErrorAction SilentlyContinue)) 
{
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Installing Microsoft UI XAML..."
    Install-Package $UIXAMLDependency -RequiredVersion 2.7 -Force
    try {
        Add-AppxPackage $UIXAMLAPPXDependency -ErrorAction Stop
    } catch {
        Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Error installing Microsoft UI XAML: $_"
        $overallStatus = $false
    }
}
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Microsoft UI XAML installation completed."

# Install VC++ Libs
# Check if VC++ Libs  is installed
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Checking for VC dependency..."
if (-not (Get-AppxPackage -Name $VCDependency -ErrorAction SilentlyContinue)) 
{
    # Install VC++
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Installing VC dependency..."
    try {
        Add-AppxPackage "./$VCDependency" -ErrorAction Stop
    } catch {
        if ($_.Exception.Message -like "*higher version*") {
            Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] A higher version of VC dependency is already installed. Continuing..."
        } else {
            Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Error installing VC dependency: $_"
            $overallStatus = $false
        }
    }
}
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] VC dependency installation completed."

# Install winget
# Check if winget is installed
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Checking for Winget..."
$wingetPackageName = $latestWingetMsixBundle.Split(".")[0]
if (-not (Get-AppxPackage -Name $wingetPackageName -ErrorAction SilentlyContinue)) 
{
    Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Installing winget..."
    try {
        Add-AppxPackage "./$latestWingetMsixBundle" -ErrorAction Stop
    } catch {
        if ($_.Exception.Message -like "*0x80073D02*" -and $_.Exception.Message -like "*error 0x80073D02: Unable to install because the following apps need to be closed Microsoft.DesktopAppInstaller*") {
            Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Microsoft.DesktopAppInstaller needs to be closed. This is not considered an error. Continuing..."
        } else {
            Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Error installing Winget: $_"
            $overallStatus = $false
        }
    }
}
Write-Information "[$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Winget installation completed."

# Output final status
if ($overallStatus) {
    Write-Host "Success!"
} else {
    Write-Host "Failed!"
}

# Stop recording interactions
Stop-Transcript

# Exit with appropriate code
exit [int](!$overallStatus)
