#!/usr/bin/env bash

# ============================================================
# C/C++ updater
# ============================================================
#
# Purpose:
#   Update the managed native toolchain installation.
#
# Notes:
#   OS-managed toolchains are left to their original manager.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint cpp "$@"