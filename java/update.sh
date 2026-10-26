#!/usr/bin/env bash

# ============================================================
# Java updater
# ============================================================
#
# Purpose:
#   Update the managed Java installation.
#
# Notes:
#   Versioned JDK package selections are preserved.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint java "$@"