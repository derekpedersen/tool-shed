#!/usr/bin/env bash

# ============================================================
# Identity update guard
# ============================================================
#
# Purpose:
#   Report that identity setup has no automatic package update.
#
# Notes:
#   Credentials and identity settings remain unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint identity "$@"