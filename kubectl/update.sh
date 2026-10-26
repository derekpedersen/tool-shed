#!/usr/bin/env bash

# ============================================================
# Kubernetes CLI updater
# ============================================================
#
# Purpose:
#   Update the managed kubectl installation.
#
# Notes:
#   Direct releases are verified against upstream SHA256 checksums.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint kubectl "$@"