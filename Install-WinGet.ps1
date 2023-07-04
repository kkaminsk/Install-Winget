# Begin recording all interactions to the log file
Start-Transcript -Path "$LogPath\wingetinstall.log"

$progressPreference = 'silentlyContinue'

# Set the environment variable for the root of the path
$LogPath = $env:temp

# Set the XML Dependency
$webview2 = "Microsoft.Web.WebView2"
$uixamldependency = "Microsoft.UI.Xaml"

# Put in the VC library details
$vcdependency = "Microsoft.VCLibs.x64.14.00.Desktop.appx"
$vcdependencyname = "Microsoft.VCLibs.140.00"

$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]

Write-Information "Downloading winget to current directory..."
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx

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

# Installs Microsoft.Web.Webview2
# Check if UI Xaml is installed
if (-not (Get-Package -Name $webview2 -ErrorAction SilentlyContinue)) {
    Write-Information "Installing Microsoft UI XAML..."
    Install-Package $webview2 -Force
}

# Installs Microsoft.UI.Xaml
# Check if UI Xaml is installed
if (-not (Get-Package -Name $UIXAMLDependency -ErrorAction SilentlyContinue)) {
    Write-Information "Installing Microsoft UI XAML..."
    Install-Package $UIXAMLDependency -Force
}

# Check if VC++ Libs  is installed
if (-not (Get-AppxPackage -Name $vcdependencyname -ErrorAction SilentlyContinue)) {
    Write-Information "Installing winget..."
    Add-AppxPackage "./$VCDependency"
}

# Check if winget is installed
$wingetPackageName = $latestWingetMsixBundle.Split(".")[0]
if (-not (Get-AppxPackage -Name $wingetPackageName -ErrorAction SilentlyContinue)) {
    Write-Information "Installing winget..."
    Add-AppxPackage "./$latestWingetMsixBundle"
}

# Stop recording interactions
Stop-Transcript