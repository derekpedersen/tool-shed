#!/usr/bin/env bash

# ============================================================
# Curl updater
# ============================================================
#
# Purpose:
#   Update the managed Curl installation.
#
# Notes:
#   System-managed installations are not replaced.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint curl "$@"