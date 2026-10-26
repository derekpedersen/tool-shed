#!/usr/bin/env bash

# ============================================================
# Kafka updater
# ============================================================
#
# Purpose:
#   Update the managed Kafka installation.
#
# Notes:
#   Service updates require explicit confirmation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint kafka "$@"