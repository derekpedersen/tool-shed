#!/usr/bin/env bash

# ============================================================
# Redis updater
# ============================================================
#
# Purpose:
#   Update the managed Redis installation.
#
# Notes:
#   Service updates require explicit confirmation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint redis "$@"