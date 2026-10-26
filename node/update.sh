#!/usr/bin/env bash

# ============================================================
# Node.js updater
# ============================================================
#
# Purpose:
#   Update the managed Node.js installation.
#
# Notes:
#   NVM installations stay within the current Node major version.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint node "$@"