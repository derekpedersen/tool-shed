# eksctl

eksctl is the official CLI for creating and managing Amazon EKS clusters from the shell. Official site: https://eksctl.io/

## What it is used for

- Creating and managing EKS clusters locally and in CI
- Automating Kubernetes node group and cluster configuration
- Provisioning AWS-based Kubernetes workloads with repeatable automation
- Supporting local cluster bootstrap and testing flows

## Files

- install.sh: install eksctl through the central installer runtime
- uninstall.sh: uninstall eksctl through the central installer runtime
- install.windows.ps1: PowerShell wrapper for eksctl installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh eksctl
bash ./.tools/uninstall.sh eksctl
```

PowerShell (Windows):

```powershell
pwsh ./eksctl/install.windows.ps1
```

