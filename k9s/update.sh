#!/usr/bin/env bash

# ============================================================
# k9s updater
# ============================================================
#
# Purpose:
#   Update the managed k9s installation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint k9s "$@"