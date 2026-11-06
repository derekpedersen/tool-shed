# unzip

unzip is a utility for extracting files from ZIP archives, commonly used for package installation and local artifact management. Official site: https://www.gnu.org/software/unzip/

## What it is used for

- Extracting packaged software and archives
- Unpacking downloaded artifacts during local setup
- Working with portable zip bundles and release files
- Supporting lightweight file extraction in dev workflows

## Files

- install.sh: install unzip through the central installer runtime
- uninstall.sh: uninstall unzip through the central installer runtime
- install.windows.ps1: PowerShell wrapper for unzip installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh unzip
bash ./.tools/uninstall.sh unzip
```

PowerShell (Windows):

```powershell
pwsh ./unzip/install.windows.ps1
```

