#!/usr/bin/env bash

# ============================================================
# Tool-shed uninstaller (shell runtime)
# ============================================================
#
# Purpose:
#   Bootstrap and run an explicitly targeted shell uninstall flow.
#
# Notes:
#   This script is intentionally shell-runtime only.
# ============================================================

set -euo pipefail

usage() {
  echo "Usage: bash uninstall.sh [full|cloud|services|ai|software-developer|data-science|TOOL ...] [--dry-run]"
  echo "A tool or bundle target is required. Preview removals with --dry-run."
}

targets=()
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) ;;
    --help|-h) usage; exit 0 ;;
    -*) ;;
    *) targets+=("$arg") ;;
  esac
done

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "An explicit uninstall target is required; refusing to default to the full bundle." >&2
  usage >&2
  exit 2
fi

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
if [[ -f "$REPO_ROOT/.tools/uninstall.sh" ]]; then
  exec bash "$REPO_ROOT/.tools/uninstall.sh" "$@"
fi

tool_shed_require_not_bootstrapped

tool_shed_bootstrap_script "uninstall.sh" "$@"
