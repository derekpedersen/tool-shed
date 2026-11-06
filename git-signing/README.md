# Git Signing

Git signing adds commit and tag verification through cryptographic keys, helping provide trust and authenticity for version control workflows. Official docs: https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work

## What it is used for

- Signing Git commits and tags with a GPG or SSH key
- Verifying code provenance in team workflows
- Supporting secure repository and release practices
- Improving trust signals in collaborative development

## Files

- install.sh: install the Git signing helper through the central installer runtime
- uninstall.sh: uninstall the Git signing helper through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Git signing helper installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh git-signing
bash ./.tools/uninstall.sh git-signing
```

PowerShell (Windows):

```powershell
pwsh ./git-signing/install.windows.ps1
```

