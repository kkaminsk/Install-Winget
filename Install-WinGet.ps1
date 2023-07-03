$progressPreference = 'silentlyContinue'

# Set the environment variable for the root of the path
$LogPath = $env:TEMP
 
# Begin recording all interactions to the log file
Start-Transcript -Path "$LogPath\wingetinstall.log"

$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]

Write-Information "Downloading winget to artifacts directory..."

Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx

Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx

# Workaround for Microsoft.UI.Xaml dependency.
# Creates an additional dependency on Microsoft.Web.Webview2

# Check if Nuget Package Provider is installed
if(-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    # Install the Nuget Package Provider
    Install-PackageProvider -Name NuGet -Force
}

# Check if Nuget Module is installed
if(-not (Get-Module -ListAvailable -Name NuGet)) {
    # Install the Nuget PowerShell Module
    Install-Module -Name NuGet -Force
}

# Check if Nuget.org repository is registered
if(-not (Get-PackageSource | Where-Object { $_.Name -eq 'nuget.org' })) {
    # Register the Nuget.org repository
    Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet
}

# Installs Microsoft.UI.Xaml and Microsoft.Web.Webview2 in one command
Install-Package Microsoft.UI.Xaml -Force
Install-AppxPackage -path "./$latestWingetMsixBundle" -force

# Stop recording interactions
Stop-Transcript