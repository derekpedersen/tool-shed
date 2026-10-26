#!/usr/bin/env bash

# ============================================================
# jq updater
# ============================================================
#
# Purpose:
#   Update the managed jq installation.
#
# Notes:
#   Shared update options and safety checks apply.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint jq "$@"