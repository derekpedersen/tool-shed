# RabbitMQ

RabbitMQ is a message broker for decoupling application components and distributing asynchronous workloads. Official site: https://www.rabbitmq.com/

## What it is used for

- Handling message queues between application services
- Supporting asynchronous job and event-driven workflows
- Decoupling producers and consumers in distributed systems
- Running local messaging infrastructure for apps and demos

## Files

- install.sh: install RabbitMQ through the central installer runtime
- uninstall.sh: uninstall RabbitMQ through the central installer runtime
- install.windows.ps1: PowerShell wrapper for RabbitMQ installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh rabbitmq
bash ./.tools/uninstall.sh rabbitmq
```

PowerShell (Windows):

```powershell
pwsh ./rabbitmq/install.windows.ps1
```

