#!/usr/bin/env bash

# ============================================================
# bat updater
# ============================================================
#
# Purpose:
#   Update the managed bat installation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint bat "$@"