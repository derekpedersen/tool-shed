# doctl

doctl is the DigitalOcean CLI for creating, inspecting, and managing cloud resources from the terminal. Official site: https://docs.digitalocean.com/reference/doctl/

## What it is used for

- Managing DigitalOcean droplets, databases, and projects
- Automating infrastructure tasks in shell scripts and CI
- Managing Kubernetes clusters and app resources on DO
- Working with cloud resources in local developer workflows

## Files

- bash.sh: shell helpers for doctl workflows
- install.sh: install doctl through the central installer runtime
- uninstall.sh: uninstall doctl through the central installer runtime
- install.windows.ps1: PowerShell wrapper for doctl installation on Windows

## Aliases

Accepted alias names: digitalocean, doks

## Usage

From repo root:

```bash
bash ./.tools/install.sh doctl
bash ./.tools/uninstall.sh doctl
```

PowerShell (Windows):

```powershell
pwsh ./doctl/install.windows.ps1
```

