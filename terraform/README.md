# Terraform

Terraform is an infrastructure-as-code tool for provisioning and managing cloud resources with declarative configuration. Official site: https://developer.hashicorp.com/terraform

## What it is used for

- Defining infrastructure as code for cloud environments
- Provisioning shared resources across dev, test, and production
- Supporting repeatable infrastructure automation in CI/CD
- Managing local and cloud-based platform setup consistently

## Files

- install.sh: install Terraform through the central installer runtime
- uninstall.sh: uninstall Terraform through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh terraform
bash ./.tools/uninstall.sh terraform
```