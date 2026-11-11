#!/usr/bin/env bash

# ============================================================
# yq updater
# ============================================================
#
# Purpose:
#   Update the managed yq installation.
#
# Notes:
#   Direct releases require a published SHA256 digest.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint yq "$@"