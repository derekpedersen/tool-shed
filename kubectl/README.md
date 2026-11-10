# kubectl

kubectl is the official Kubernetes command-line tool for interacting with clusters, workloads, and configuration. Official site: https://kubernetes.io/docs/reference/kubectl/

## What it is used for

- Managing Kubernetes resources and workloads from the shell
- Debugging deployments, pods, and service state
- Applying manifests and inspecting cluster configuration
- Supporting local and production Kubernetes operations

## Files

- bash.sh: shell helpers for kubectl workflows
- install.sh: install kubectl through the central installer runtime
- uninstall.sh: uninstall kubectl through the central installer runtime
- install.windows.ps1: PowerShell wrapper for kubectl installation on Windows

## Aliases

Accepted alias names: kubernetes-cli

## Usage

From repo root:

```bash
bash ./.tools/install.sh kubectl
bash ./.tools/uninstall.sh kubectl
```

PowerShell (Windows):

```powershell
pwsh ./kubectl/install.windows.ps1
```

