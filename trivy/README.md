# Trivy

Trivy is a security scanner for vulnerabilities and configuration issues in files, containers, and infrastructure-as-code. Official site: https://trivy.dev/

## What it is used for

- Scanning container images and local files for vulnerabilities
- Reviewing IaC and config issues before deployment
- Supporting security checks in local tooling and CI pipelines
- Improving operational confidence in app and infra hygiene

## Files

- install.sh: install Trivy through the central installer runtime
- uninstall.sh: uninstall Trivy through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh trivy
bash ./.tools/uninstall.sh trivy
```