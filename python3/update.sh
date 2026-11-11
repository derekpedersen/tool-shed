#!/usr/bin/env bash

# ============================================================
# Python updater
# ============================================================
#
# Purpose:
#   Update the managed Python installation.
#
# Notes:
#   Developer packages are updated only with --with-packages.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint python3 "$@"