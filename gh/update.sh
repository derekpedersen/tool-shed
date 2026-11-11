#!/usr/bin/env bash

# ============================================================
# GitHub CLI updater
# ============================================================
#
# Purpose:
#   Update the managed GitHub CLI installation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint gh "$@"