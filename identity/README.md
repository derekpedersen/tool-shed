# Identity Helpers

This module provides identity-focused shell patterns and local auth-related helper setup for developer environments. Official docs: https://openid.net/

## What it is used for

- Supporting identity and authentication helper workflows
- Organizing local auth configuration patterns in shell environments
- Keeping developer access setup consistent across machines
- Providing a discoverable home for identity-related automation helpers

## Files

- install.sh: install the identity helper through the central installer runtime
- uninstall.sh: uninstall the identity helper through the central installer runtime
- install.windows.ps1: PowerShell wrapper for identity helper installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh identity
bash ./.tools/uninstall.sh identity
```

PowerShell (Windows):

```powershell
pwsh ./identity/install.windows.ps1
```

