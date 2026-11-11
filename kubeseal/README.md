# kubeseal

kubeseal encrypts Kubernetes Secrets so they can be safely stored and distributed in GitOps workflows. Official site: https://github.com/bitnami-labs/sealed-secrets

## What it is used for

- Sealing sensitive Kubernetes configuration before committing it
- Supporting GitOps and secret delivery workflows
- Reducing the risk of exposing plaintext secrets in version control
- Working with sealed secret flows in Kubernetes environments

## Files

- install.sh: install kubeseal through the central installer runtime
- uninstall.sh: uninstall kubeseal through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh kubeseal
bash ./.tools/uninstall.sh kubeseal
```