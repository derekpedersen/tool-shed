#!/usr/bin/env bash

# ============================================================
# Docker updater
# ============================================================
#
# Purpose:
#   Update the managed Docker installation.
#
# Notes:
#   Package updates can restart Docker and affect running containers.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint docker "$@"