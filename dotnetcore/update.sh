#!/usr/bin/env bash

# ============================================================
# .NET updater
# ============================================================
#
# Purpose:
#   Update the managed .NET SDK installation.
#
# Notes:
#   Versioned package selections are preserved.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint dotnetcore "$@"