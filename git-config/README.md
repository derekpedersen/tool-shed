# Git Config Helpers

This module provides Git configuration helpers for standard local developer setup and shell convenience patterns. Official site: https://git-scm.com/

## What it is used for

- Applying shared Git identity and alias conventions
- Automating common developer Git configuration tasks
- Keeping repo setup consistent across local environments
- Supporting a faster bootstrap for new dev machines

## Files

- install.sh: install the Git config helper through the central installer runtime
- uninstall.sh: uninstall the Git config helper through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Git config helper installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh git-config
bash ./.tools/uninstall.sh git-config
```

PowerShell (Windows):

```powershell
pwsh ./git-config/install.windows.ps1
```

