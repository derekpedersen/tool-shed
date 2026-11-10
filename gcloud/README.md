# Google Cloud SDK

The Google Cloud SDK provides the `gcloud` command-line interface for authenticating to Google Cloud, managing projects, and deploying cloud resources. Official site: https://cloud.google.com/sdk

## What it is used for

- Authenticating to Google Cloud projects
- Managing compute, storage, networking, and container resources
- Deploying applications and infrastructure to GCP
- Working with GKE, Cloud Run, and other Google Cloud services

## Files

- bash.sh: shell helpers for Google Cloud workflows
- install.sh: install Google Cloud SDK through the central installer runtime
- uninstall.sh: uninstall Google Cloud SDK through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Google Cloud SDK installation on Windows

## Aliases

Accepted alias names: google-cloud

## Usage

From repo root:

```bash
bash ./.tools/install.sh gcloud
bash ./.tools/uninstall.sh gcloud
```

PowerShell (Windows):

```powershell
pwsh ./gcloud/install.windows.ps1
```

