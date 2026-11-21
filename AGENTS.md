# AGENTS.md

## Overview
This repository contains a tool shed of bash helper modules, local developer install scripts, and small operational automation for macOS and Debian-based Linux environments.

## Principles
- Keep automation safe to rerun.
- Favor explicit, readable shell code over clever or opaque patterns.
- Keep OS-specific logic separate from the controller logic.
- Prefer bundle-based install flows and expose those names clearly in usage output.
- Treat destructive tooling as opt-in and confirm before deletion or cleanup.

## File layout
- `.bash/install.sh` / `.bash/uninstall.sh` / `.bash/README.md`: Bash helper entrypoints and docs
- `.tools/install.sh` / `.tools/uninstall.sh` / `.tools/README.md`: installer/runtime entrypoints and documentation
- `.tools/common.sh` / `.tools/module-runtime.sh` / `.tools/macos.sh` / `.tools/linux.sh` / `.tools/windows.sh`: shared installer runtime and platform logic
- `.tools/install.ps1` / `.tools/uninstall.ps1`: PowerShell wrappers for Windows
- `<tool>/`: per-tool modules at repo root containing `install.sh`, `uninstall.sh`, optional `install.windows.ps1`, and optional `bash.sh`
- `.services/`: local Docker Compose service stack, including `local-dev.sh`, `docker-compose.yml`, `grafana/`, and `prometheus/`
- `helm/`: Helm-related helper scripts
- `Makefile`: shared build and test entry points used by both local runs and Jenkins
- `README.md`: top-level docs for repo usage

The repository uses a module-vs-runtime split:
- the `.tools/*` files are the control plane for bundle selection and OS-specific behavior
- the root-level `<tool>/` directories are the actual module packages
- `.services/` is its own domain for local developer infrastructure, not part of the tool installation runtime
- the `.bash/` helpers are a separate shell helper layer loaded via the managed install flow, not part of the tool installation runtime

## Comment and documentation conventions
- Use the project header format shown in existing scripts.
- Keep comments short and purpose-oriented.
- Update documentation when bundle names, tool names, or helper behavior change.

README format standard:
- Keep module READMEs concise and predictable using this section order:
	1. short intro paragraph,
	2. "Why this tool" bullets,
	3. "Files" list,
	4. "Usage" examples,
	5. "Notes" for platform and safety behavior.
- Use canonical bundle names only: `full`, `cloud`, `services`, `ai`, `software-developer`, `data-science`.
- Root-runtime docs must reflect current behavior: root wrappers are runtime selectors, `.scripts/` contains shell-only wrappers, and Go runtime attempts matching prebuilt binary download before shell fallback.
- Keep examples copy-paste ready (`bash ...` / `curl ... | bash -s -- ...`) and avoid stale paths or renamed script references.

## Shell guidelines
- Use `set -euo pipefail` where appropriate.
- Validate user input and provide helpful usage text.
- Check for command availability before installation or execution.
- Prefer idempotent installation logic so rerunning scripts does not duplicate profile entries or reinstall packages unnecessarily.

## AI / automation guidance
- Keep changes consistent with the current repo patterns.
- Do not add hidden magic; prefer discoverable names and straightforward behavior.
- Update both bundle definitions and user-facing usage output when adding or changing install options.
- Prefer adding new CI and validation behavior to `Makefile` targets first, then have `Jenkinsfile` call those targets.
- Keep `build` for fast validation and `test` for installer smoke checks, including install and uninstall dry-run coverage.
- Preserve compatibility with macOS and Debian-based Linux unless specifically directed otherwise.
