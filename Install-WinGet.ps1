$progressPreference = 'silentlyContinue'
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Set the environment variable for the root of the path
$LogPath = $env:TEMP

# Set the XML Dependency
$UIXAMLDependency = "Microsoft.UI.Xaml"
$UIXAMLAPPXDependency = $env:ProgramFiles + "\PackageManagement\NuGet\Packages\Microsoft.UI.Xaml.2.7.0\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"
$VCDependency = "Microsoft.VCLibs.x64.14.00.Desktop.appx"

# Begin recording all interactions to the log file
Start-Transcript -Path "$LogPath\wingetinstall.log"

$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]

Write-Information "Downloading winget to current directory..."
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx

# Workaround for Microsoft.UI.Xaml dependency.
# Creates an additional dependency on Microsoft.Web.Webview2
# Detection logic was breaking the silent install. Just installing NuGet's package provider.
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -Confirm:$false


# Check if Nuget Module is installed
if(-not (Get-Module -ListAvailable -Name NuGet)) {
    # Install the Nuget PowerShell Module
    Install-Module -Name NuGet -Force
}

# Check if Nuget.org repository is registered
if(-not (Get-PackageSource | Where-Object { $_.Name -eq 'nuget.org' })) 
{
    # Register the Nuget.org repository
    Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet
}

# Installs Microsoft.UI.Xaml
# Check if UI Xaml is installed
if (-not (Get-Package -Name $UIXAMLDependency -RequiredVersion 2.7 -ErrorAction SilentlyContinue)) 
{
    Write-Information "Installing Microsoft UI XAML..."
    Install-Package $UIXAMLDependency -RequiredVersion 2.7 -Force
    Add-AppxPackage $UIXAMLAPPXDependency
}

# Check if VC++ Libs  is installed
if (-not (Get-AppxPackage -Name $VCDependency -ErrorAction SilentlyContinue)) 
{
    Write-Information "Installing VC dependency..."
    Add-AppxPackage "./$VCDependency" -ErrorAction SilentlyContinue
}

# Check if winget is installed
$wingetPackageName = $latestWingetMsixBundle.Split(".")[0]
if (-not (Get-AppxPackage -Name $wingetPackageName -ErrorAction SilentlyContinue)) 
{
    Write-Information "Installing winget..."
    Add-AppxPackage "./$latestWingetMsixBundle"
}

# Stop recording interactions
Stop-Transcript