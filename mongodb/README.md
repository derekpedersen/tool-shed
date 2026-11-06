# MongoDB

MongoDB is a document-oriented NoSQL database for flexible JSON-like data models and application workloads. Official site: https://www.mongodb.com/

## What it is used for

- Running document-based local app data stores
- Supporting JSON-centric application development and testing
- Working with event-driven and flexible-schema workloads
- Providing a local database for app demos and service stacks

## Files

- install.sh: install MongoDB through the central installer runtime
- uninstall.sh: uninstall MongoDB through the central installer runtime
- install.windows.ps1: PowerShell wrapper for MongoDB installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh mongodb
bash ./.tools/uninstall.sh mongodb
```

PowerShell (Windows):

```powershell
pwsh ./mongodb/install.windows.ps1
```

