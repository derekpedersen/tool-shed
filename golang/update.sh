#!/usr/bin/env bash

# ============================================================
# Go updater
# ============================================================
#
# Purpose:
#   Update the managed Go installation.
#
# Notes:
#   Direct updates preserve the previous installation as a backup.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint golang "$@"