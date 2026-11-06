# nvm

nvm is a Node version manager that lets you install and switch between multiple Node.js runtime versions on the same machine. Official site: https://github.com/nvm-sh/nvm

## What it is used for

- Installing and switching between Node.js versions locally
- Matching project runtime requirements across different repos
- Supporting frontend and backend tooling on a single workstation
- Keeping Node development environments predictable and reproducible

## Files

- install.sh: install nvm through the central installer runtime
- uninstall.sh: uninstall nvm through the central installer runtime
- install.windows.ps1: PowerShell wrapper for nvm installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh nvm
bash ./.tools/uninstall.sh nvm
```

PowerShell (Windows):

```powershell
pwsh ./nvm/install.windows.ps1
```

