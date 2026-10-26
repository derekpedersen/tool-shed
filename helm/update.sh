#!/usr/bin/env bash

# ============================================================
# Helm updater
# ============================================================
#
# Purpose:
#   Update the managed Helm installation.
#
# Notes:
#   Major-version changes require explicit opt-in.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint helm "$@"