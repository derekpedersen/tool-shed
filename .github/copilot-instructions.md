# Copilot instructions for this repo

## Project purpose
This repository stores a curated tool shed of reusable shell helpers, DevOps bootstrap scripts, and small operational tooling for local development. The goal is to make common workflows fast, explicit, and easy to discover from the shell.

## Coding conventions
- Prefer clear, readable shell scripting over clever one-liners.
- Favor small, composable functions with obvious names.
- Keep destructive commands explicit and confirm before deleting data.
- Prefer bash-compatible syntax with portable patterns for macOS and Debian-based Linux.
- When adding install logic, keep OS-specific behavior in the platform files and keep the entrypoint controller thin.

## Comment style
Use this header pattern at the top of new script files:

```bash
#!/usr/bin/env bash

# ============================================================
# <Short script name>
# ============================================================
#
# Purpose:
#   Describe what the script or helper file is for.
#
# Notes:
#   Call out any important conventions, warnings, or environment assumptions.
# ============================================================
```

For helper functions inside a file, use short one-line comments that explain intent, not implementation detail.

Examples:

```bash
# Current context
kctx() {
  kubectl config current-context
}

# Log in to a Docker registry
docker-login() {
  docker login "$@"
}
```

## File patterns
- Bash helper module files go in repo-root tool folders as `<tool>/bash.sh`.
- Tool installer entrypoints live under `.tools/` as `install.sh` and `uninstall.sh` and dispatch to per-tool modules.
- Bash helper entrypoints live under `.bash/` as `install.sh` and `uninstall.sh`.
- Keep bundle names stable in `.tools/common.sh` and keep usage text in sync with `.tools/install.sh`.
- Prefer functions and aliases that are discoverable by name.

## README format
- Keep module README files consistent and easy to scan with this section flow:
  1. short intro paragraph,
  2. "Why this tool" bullets,
  3. "Files" list,
  4. "Usage" examples,
  5. "Notes" for platform and safety behavior.
- Use canonical bundle names only: `full`, `cloud`, `services`, `ai`, `software-developer`, `data-science`.
- For root runtime docs, describe the current flow accurately:
  - root `install.sh`, `list.sh`, `update.sh`, and `uninstall.sh` are runtime selectors,
  - `.scripts/` contains shell-only wrapper entrypoints,
  - `--runtime go` attempts local binary resolution first, then downloads the matching prebuilt binary for detected OS/arch, then falls back to shell runtime.
- Keep commands copy-paste ready and current; avoid stale script names or paths.

## Shell conventions
- Use `set -euo pipefail` at the top of scripts when appropriate.
- Validate arguments with clear usage messages.
- Prefer `command -v` checks before invoking external tools.
- Avoid silent failure for destructive operations.
- Use `--dry-run` support for install flows when adding or testing new bundles.

## AI assistant guidance
- Keep changes minimal and aligned to the repo’s existing patterns.
- Maintain compatibility with macOS and Debian-based Linux unless the task explicitly calls for a narrower target.
- When editing scripts, preserve the repo’s idempotent behavior and safe rerun semantics.
- If a new helper is added under a module folder (`<tool>/bash.sh`), ensure it is consistent with the existing helper naming and loading flow.
- If a new tool is added to install logic, add its module folder and update bundle definitions and usage output together.
