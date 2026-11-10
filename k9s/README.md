# k9s

k9s is a terminal-based Kubernetes dashboard for navigating clusters, pods, and workloads quickly. Official site: https://k9scli.io/

## What it is used for

- Inspecting Kubernetes resources from the terminal
- Debugging pods, services, deployments, and namespaces
- Monitoring cluster state and workloads during development
- Supporting day-to-day Kubernetes troubleshooting and operations

## Files

- install.sh: install k9s through the central installer runtime
- uninstall.sh: uninstall k9s through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh k9s
bash ./.tools/uninstall.sh k9s
```