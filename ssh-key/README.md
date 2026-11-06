# SSH Keys

SSH keys provide a secure way to authenticate to remote hosts without entering a password repeatedly. Official docs: https://www.ssh.com/academy/ssh/keygen

## What it is used for

- Generating SSH keypairs for remote Linux and server access
- Enabling secure, passwordless authentication for dev workflows
- Working with GitHub, servers, and cloud hosts
- Providing a common local developer identity for remote access

## Files

- install.sh: install the SSH key helper through the central installer runtime
- uninstall.sh: uninstall the SSH key helper through the central installer runtime
- install.windows.ps1: PowerShell wrapper for SSH key helper installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh ssh-key
bash ./.tools/uninstall.sh ssh-key
```

PowerShell (Windows):

```powershell
pwsh ./ssh-key/install.windows.ps1
```

