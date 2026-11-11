# Docker

Docker packages applications and dependencies into portable containers so they run consistently across local machines, CI, and production. Official site: https://www.docker.com/

## What it is used for

- Running local services and developer stacks in containers
- Packaging app dependencies for reliable builds and testing
- Supporting microservice and multi-container development workflows
- Creating repeatable CI/CD environments

## Files

- bash.sh: shell helpers for Docker workflows
- install.sh: install Docker through the central installer runtime
- uninstall.sh: uninstall Docker through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Docker installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh docker
bash ./.tools/uninstall.sh docker
```

PowerShell (Windows):

```powershell
pwsh ./docker/install.windows.ps1
```

