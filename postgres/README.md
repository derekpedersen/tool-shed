# PostgreSQL

PostgreSQL is a powerful open-source relational database commonly used for application data, local development, and production workloads. Official site: https://www.postgresql.org/

## What it is used for

- Hosting application databases for local development
- Supporting data-backed services and schema work
- Running relational database workloads in dev and test setups
- Providing a reliable SQL engine for app and analytics use cases

## Files

- install.sh: install PostgreSQL through the central installer runtime
- uninstall.sh: uninstall PostgreSQL through the central installer runtime
- install.windows.ps1: PowerShell wrapper for PostgreSQL installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh postgres
bash ./.tools/uninstall.sh postgres
```

PowerShell (Windows):

```powershell
pwsh ./postgres/install.windows.ps1
```

