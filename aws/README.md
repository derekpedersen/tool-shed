# AWS CLI

The AWS CLI lets you manage Amazon Web Services from the shell for deployment, automation, and infrastructure operations. Official site: https://aws.amazon.com/cli/

## What it is used for

- Managing AWS accounts, IAM, and cloud resources
- Deploying infrastructure and application stacks from scripts
- Automating dev and ops tasks in CI/CD environments
- Working with S3, EC2, EKS, and other AWS services from the terminal

## Files

- bash.sh: shell helpers for AWS workflows
- install.sh: install AWS CLI through the central installer runtime
- uninstall.sh: uninstall AWS CLI through the central installer runtime
- install.windows.ps1: PowerShell wrapper for AWS CLI installation on Windows

## Aliases

Accepted alias names: awscli

## Usage

From repo root:

```bash
bash ./.tools/install.sh aws
bash ./.tools/uninstall.sh aws
```

PowerShell (Windows):

```powershell
pwsh ./aws/install.windows.ps1
```

