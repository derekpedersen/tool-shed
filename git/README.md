# Git

Git is the standard version control system for tracking code changes, collaborating on repositories, and managing project history. Official site: https://git-scm.com/

## What it is used for

- Tracking source changes across repositories and branches
- Collaborating with teams on shared codebases
- Managing commit history, tags, and code review workflows
- Supporting local and remote development workflows across projects

## Files

- bash.sh: shell helpers for Git workflows
- install.sh: install Git through the central installer runtime
- uninstall.sh: uninstall Git through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Git installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh git
bash ./.tools/uninstall.sh git
```

PowerShell (Windows):

```powershell
pwsh ./git/install.windows.ps1
```

