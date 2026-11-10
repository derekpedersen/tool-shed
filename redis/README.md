# Redis

Redis is an in-memory data store used for caching, sessions, queues, and fast read-heavy workloads. Official site: https://redis.io/

## What it is used for

- Caching frequently accessed data in local and production apps
- Supporting session storage and lightweight queue patterns
- Speeding up app performance for read-heavy workloads
- Running local dev stacks with cache and message patterns

## Files

- install.sh: install Redis through the central installer runtime
- uninstall.sh: uninstall Redis through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Redis installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh redis
bash ./.tools/uninstall.sh redis
```

PowerShell (Windows):

```powershell
pwsh ./redis/install.windows.ps1
```

