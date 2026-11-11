# wget

wget is a command-line utility for downloading files from the web using HTTP, HTTPS, and FTP. Official site: https://www.gnu.org/software/wget/

## What it is used for

- Downloading files from remote endpoints
- Fetching artifacts and distributions for local setup
- Supporting scriptable network automation and CI tasks
- Working with CLI-based file retrieval in developer workflows

## Files

- install.sh: install wget through the central installer runtime
- uninstall.sh: uninstall wget through the central installer runtime
- install.windows.ps1: PowerShell wrapper for wget installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh wget
bash ./.tools/uninstall.sh wget
```

PowerShell (Windows):

```powershell
pwsh ./wget/install.windows.ps1
```

