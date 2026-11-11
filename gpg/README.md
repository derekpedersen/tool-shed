# GPG

GPG is a cryptography tool for signing, encrypting, and managing keys used to verify identity and protect data. Official site: https://gnupg.org/

## What it is used for

- Creating and managing GPG keys for secure signing
- Signing Git commits and tags
- Encrypting and decrypting files in local workflows
- Supporting secure developer identity and trust practices

## Files

- install.sh: install GPG through the central installer runtime
- uninstall.sh: uninstall GPG through the central installer runtime
- install.windows.ps1: PowerShell wrapper for GPG installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh gpg
bash ./.tools/uninstall.sh gpg
```

PowerShell (Windows):

```powershell
pwsh ./gpg/install.windows.ps1
```

