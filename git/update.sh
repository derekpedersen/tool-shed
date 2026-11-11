#!/usr/bin/env bash

# ============================================================
# Git updater
# ============================================================
#
# Purpose:
#   Update the managed Git installation.
#
# Notes:
#   Identity, signing configuration, and credentials are unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint git "$@"