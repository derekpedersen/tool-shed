#!/usr/bin/env bash

# ============================================================
# GPG updater
# ============================================================
#
# Purpose:
#   Update the managed GPG installation.
#
# Notes:
#   Existing keys remain unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint gpg "$@"