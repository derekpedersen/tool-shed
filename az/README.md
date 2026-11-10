# Azure CLI

The Azure CLI provides shell access to Microsoft Azure services for provisioning, automation, and resource management. Official site: https://learn.microsoft.com/cli/azure/

## What it is used for

- Managing Azure subscriptions, resource groups, and services
- Provisioning infrastructure and app resources from the terminal
- Automating Azure deployments in local and CI workflows
- Working with AKS, App Service, storage, and other Azure platforms

## Files

- bash.sh: shell helpers for Azure workflows
- install.sh: install Azure CLI through the central installer runtime
- uninstall.sh: uninstall Azure CLI through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Azure CLI installation on Windows

## Aliases

Accepted alias names: azure, azure-cli

## Usage

From repo root:

```bash
bash ./.tools/install.sh az
bash ./.tools/uninstall.sh az
```

PowerShell (Windows):

```powershell
pwsh ./az/install.windows.ps1
```

