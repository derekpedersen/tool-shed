#!/usr/bin/env bash

# ============================================================
# Git configuration update guard
# ============================================================
#
# Purpose:
#   Report that configuration has no automatic package update.
#
# Notes:
#   Existing identity settings remain unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint git-config "$@"