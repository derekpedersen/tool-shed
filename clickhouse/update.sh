#!/usr/bin/env bash

# ============================================================
# ClickHouse updater
# ============================================================
#
# Purpose:
#   Update the managed ClickHouse installation.
#
# Notes:
#   Service updates require explicit confirmation.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint clickhouse "$@"