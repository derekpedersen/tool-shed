#!/usr/bin/env bash

# ============================================================
# Scala CLI updater
# ============================================================
#
# Purpose:
#   Update the managed Scala CLI installation.
#
# Notes:
#   Direct releases require a published SHA256 digest.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint scala "$@"