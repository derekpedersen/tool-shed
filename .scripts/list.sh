#!/usr/bin/env bash

# ============================================================
# Tool-shed inventory (shell runtime)
# ============================================================
#
# Purpose:
#   Bootstrap and run the standalone shell inventory command.
#
# Notes:
#   This script is intentionally shell-runtime only.
# ============================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
if [[ -f "$REPO_ROOT/.tools/list.sh" ]]; then
  exec bash "$REPO_ROOT/.tools/list.sh" "$@"
fi

tool_shed_require_not_bootstrapped

tool_shed_bootstrap_script "list.sh" "$@"
