# MySQL

MySQL is a widely used relational database engine for application data, local development, and data-backed services. Official site: https://www.mysql.com/

## What it is used for

- Running a local relational database for application development
- Supporting SQL-backed app workflows and testing
- Managing persistent data for dev and demo environments
- Providing a common database platform for app integration work

## Files

- install.sh: install MySQL through the central installer runtime
- uninstall.sh: uninstall MySQL through the central installer runtime
- install.windows.ps1: PowerShell wrapper for MySQL installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh mysql
bash ./.tools/uninstall.sh mysql
```

PowerShell (Windows):

```powershell
pwsh ./mysql/install.windows.ps1
```

