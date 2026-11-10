# Elasticsearch

Elasticsearch is a distributed search and analytics engine commonly used for logs, search, and observability data. Official site: https://www.elastic.co/elasticsearch/

## What it is used for

- Indexing and searching large datasets and logs
- Supporting observability and analytics workflows
- Enabling search-focused app features and log analysis
- Running local search infrastructure for dev and testing

## Files

- install.sh: install Elasticsearch through the central installer runtime
- uninstall.sh: uninstall Elasticsearch through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Elasticsearch installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh elasticsearch
bash ./.tools/uninstall.sh elasticsearch
```

PowerShell (Windows):

```powershell
pwsh ./elasticsearch/install.windows.ps1
```

