# Helm

Helm is the package manager for Kubernetes that helps define, install, and upgrade applications using reusable charts. Official site: https://helm.sh/

## What it is used for

- Packaging and deploying Kubernetes applications with charts
- Managing release lifecycle and configuration across environments
- Reusing standardized deployment templates in local and cluster workflows
- Supporting local Kubernetes app installation and operations

## Files

- bash.sh: shell helpers for Helm workflows and version helpers
- install.sh: install Helm through the central installer runtime
- uninstall.sh: uninstall Helm through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Helm installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh helm
bash ./.tools/uninstall.sh helm
```

Then use the installed helpers from your shell:

```bash
helm-set-version
helm-show-version
```

PowerShell (Windows):

```powershell
pwsh ./helm/install.windows.ps1
```

