# curl

curl is a command-line tool for transferring data from or to a server using URLs. Official site: https://curl.se/

## What it is used for

- Fetching APIs and endpoints from the command line
- Testing HTTP services during development
- Downloading files and validating response payloads
- Working with REST and network troubleshooting tasks

## Files

- install.sh: install curl through the central installer runtime
- uninstall.sh: uninstall curl through the central installer runtime
- install.windows.ps1: PowerShell wrapper for curl installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh curl
bash ./.tools/uninstall.sh curl
```

PowerShell (Windows):

```powershell
pwsh ./curl/install.windows.ps1
```

