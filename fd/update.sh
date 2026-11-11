#!/usr/bin/env bash

# ============================================================
# fd updater
# ============================================================
#
# Purpose:
#   Update the managed fd installation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint fd "$@"