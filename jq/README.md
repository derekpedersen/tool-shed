# jq

jq is a lightweight command-line JSON processor for filtering, formatting, and inspecting JSON data from the shell. Official site: https://jqlang.github.io/jq/

## What it is used for

- Parsing and filtering JSON payloads in scripts
- Inspecting API responses and structured data quickly
- Building shell-based automation around JSON inputs and outputs
- Simplifying ad hoc data inspection during debugging

## Files

- install.sh: install jq through the central installer runtime
- uninstall.sh: uninstall jq through the central installer runtime
- install.windows.ps1: PowerShell wrapper for jq installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh jq
bash ./.tools/uninstall.sh jq
```

PowerShell (Windows):

```powershell
pwsh ./jq/install.windows.ps1
```

