#!/usr/bin/env bash

# ============================================================
# VS Code updater
# ============================================================
#
# Purpose:
#   Update the managed Visual Studio Code installation.
#
# Notes:
#   Extensions and user settings remain unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint vscode "$@"