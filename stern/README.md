# stern

stern tails logs from multiple Kubernetes pods and containers at the same time, making cluster debugging much easier. Official site: https://github.com/stern/stern

## What it is used for

- Watching logs across multiple pods at once
- Debugging application and service behavior in Kubernetes
- Filtering logs by container or workload during troubleshooting
- Supporting local cluster development and operational review

## Files

- install.sh: install stern through the central installer runtime
- uninstall.sh: uninstall stern through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh stern
bash ./.tools/uninstall.sh stern
```