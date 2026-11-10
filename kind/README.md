# kind

kind creates local Kubernetes clusters for development and testing using containers on your workstation. Official site: https://kind.sigs.k8s.io/

## What it is used for

- Running local Kubernetes clusters for dev and testing
- Supporting app validation in an isolated cluster environment
- Working with Kubernetes manifests and local service testing
- Creating lightweight, container-based cluster workflows

## Files

- install.sh: install kind through the central installer runtime
- uninstall.sh: uninstall kind through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh kind
bash ./.tools/uninstall.sh kind
```