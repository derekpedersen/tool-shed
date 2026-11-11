# Visual Studio Code

Visual Studio Code is a lightweight but powerful code editor used for development across many languages and workflows. Official site: https://code.visualstudio.com/

## What it is used for

- Editing code and configuration files locally
- Working across multiple languages and repos
- Supporting extensions, debugging, and local tooling
- Providing a consistent developer workstation editor for shell-driven workflows

## Files

- install.sh: install VS Code through the central installer runtime
- uninstall.sh: uninstall VS Code through the central installer runtime
- install.windows.ps1: PowerShell wrapper for VS Code installation on Windows

## Aliases

Accepted alias names: code

## Usage

From repo root:

```bash
bash ./.tools/install.sh vscode
bash ./.tools/uninstall.sh vscode
```

PowerShell (Windows):

```powershell
pwsh ./vscode/install.windows.ps1
```

