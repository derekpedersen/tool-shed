# .NET SDK

The .NET SDK is a cross-platform development toolkit for building and running .NET applications. Official site: https://dotnet.microsoft.com/

## What it is used for

- Building .NET and C# applications locally
- Running SDK tools for app development and testing
- Supporting backend, API, and cloud-native workloads
- Providing the standard platform for .NET-based projects

## Files

- install.sh: install the .NET SDK through the central installer runtime
- uninstall.sh: uninstall the .NET SDK through the central installer runtime
- install.windows.ps1: PowerShell wrapper for .NET SDK installation on Windows

## Aliases

Accepted alias names: dotnet

## Usage

From repo root:

```bash
bash ./.tools/install.sh dotnetcore
bash ./.tools/uninstall.sh dotnetcore
```

PowerShell (Windows):

```powershell
pwsh ./dotnetcore/install.windows.ps1
```

