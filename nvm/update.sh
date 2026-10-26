#!/usr/bin/env bash

# ============================================================
# NVM updater
# ============================================================
#
# Purpose:
#   Update the managed Node Version Manager installation.
#
# Notes:
#   Local modifications are preserved by refusing dirty checkouts.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint nvm "$@"