#!/usr/bin/env bash

# ============================================================
# R updater
# ============================================================
#
# Purpose:
#   Update the managed R installation.
#
# Notes:
#   CRAN packages remain project-managed.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint r "$@"