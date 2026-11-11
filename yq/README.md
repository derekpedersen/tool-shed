# yq

yq is a command-line tool for processing YAML data, making it easier to query, transform, and inspect configuration files. Official site: https://mikefarah.gitbook.io/yq/

## What it is used for

- Querying and transforming YAML files from the shell
- Inspecting Kubernetes and config manifests
- Supporting automation and config review tasks
- Making YAML easier to use in local tooling and scripts

## Files

- install.sh: install yq through the central installer runtime
- uninstall.sh: uninstall yq through the central installer runtime
- install.windows.ps1: PowerShell wrapper for yq installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh yq
bash ./.tools/uninstall.sh yq
```

PowerShell (Windows):

```powershell
pwsh ./yq/install.windows.ps1
```

