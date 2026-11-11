#!/usr/bin/env bash

# ============================================================
# Wget updater
# ============================================================
#
# Purpose:
#   Update the managed Wget installation.
#
# Notes:
#   Shared update options and safety checks apply.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint wget "$@"