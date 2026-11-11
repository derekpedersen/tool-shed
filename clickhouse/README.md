# ClickHouse

ClickHouse is a columnar database for analytical queries, metrics, and event-driven observability workloads. Official site: https://clickhouse.com/

## What it is used for

- Running analytics-focused local databases
- Supporting metrics, search, and observability datasets
- Handling large read-heavy analytical workloads efficiently
- Providing a dev-friendly database for dashboards and data experiments

## Files

- install.sh: install ClickHouse through the central installer runtime
- uninstall.sh: uninstall ClickHouse through the central installer runtime
- install.windows.ps1: PowerShell wrapper for ClickHouse installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh clickhouse
bash ./.tools/uninstall.sh clickhouse
```

PowerShell (Windows):

```powershell
pwsh ./clickhouse/install.windows.ps1
```

