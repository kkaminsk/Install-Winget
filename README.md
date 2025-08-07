# Install-WinGet

This PowerShell script automates the installation of Winget (Windows Package Manager) and its required dependencies.

## Description

`Install-WinGet.ps1` is designed to simplify the process of installing Winget on Windows systems. It handles the following tasks:

- Downloading the latest version of Winget
- Installing necessary dependencies (Microsoft.UI.Xaml and VC++ Libs)
- Managing potential errors during the installation process
- Providing detailed logging of the installation steps

## Prerequisites

- Windows PowerShell 5.1
- Windows 10 version 1809 (build 17763) or later

Note: This script is not compatible with PowerShell 7 or later versions.

## Usage

1. Open a PowerShell window with administrator privileges.
2. Navigate to the directory containing the script.
3. Run the script:

```powershell
.\Install-WinGet.ps1
```

## Features

- Automatic download of the latest Winget version
- Installation of required dependencies
- Detailed error handling and logging
- Compatibility checks for existing installations
- Clear success/failure status output

## Logging

The script creates a log file named `wingetinstall.log` in the system's temp folder. This log contains detailed information about each step of the installation process.

## Error Handling

The script includes robust error handling for various scenarios:

- Treats installation of higher versions of dependencies as a success
- Handles specific error cases, such as when Microsoft.DesktopAppInstaller needs to be closed

## Exit Codes

- 0: Installation successful
- 1: Installation failed

These exit codes can be used for integration with other scripts or automation tools.

## Contributing

Contributions to improve the script are welcome. Please submit a pull request or open an issue to discuss proposed changes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Kevin Kaminski

## Acknowledgments

- Microsoft for creating Winget
- The PowerShell community for valuable insights and best practices
