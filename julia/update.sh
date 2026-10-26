#!/usr/bin/env bash

# ============================================================
# Julia updater
# ============================================================
#
# Purpose:
#   Update the managed Julia installation.
#
# Notes:
#   Juliaup channel updates require explicit major-version opt-in.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint julia "$@"