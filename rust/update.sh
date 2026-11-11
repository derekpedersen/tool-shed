#!/usr/bin/env bash

# ============================================================
# Rust updater
# ============================================================
#
# Purpose:
#   Update managed Rust toolchains through rustup.
#
# Notes:
#   Existing default toolchain selections remain unchanged.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.tools/update-runtime.sh"
module_update_entrypoint rust "$@"