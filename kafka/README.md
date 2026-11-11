# Kafka

Apache Kafka is a distributed event streaming platform used for topics, event pipelines, and real-time data processing. Official site: https://kafka.apache.org/

## What it is used for

- Streaming events between services and systems
- Supporting real-time data pipelines and integrations
- Handling high-throughput message processing in distributed apps
- Running local event-streaming infrastructure for dev workloads

## Files

- install.sh: install Kafka through the central installer runtime
- uninstall.sh: uninstall Kafka through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Kafka installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh kafka
bash ./.tools/uninstall.sh kafka
```

PowerShell (Windows):

```powershell
pwsh ./kafka/install.windows.ps1
```

