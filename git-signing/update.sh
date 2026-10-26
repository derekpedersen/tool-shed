#!/usr/bin/env bash

# ============================================================
# Git signing update guard
# ============================================================
#
# Purpose:
#   Report that signing setup has no automatic package update.
#
# Notes:
#   Existing signing keys and settings remain unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint git-signing "$@"