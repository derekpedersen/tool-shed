#!/usr/bin/env bash

# ============================================================
# Tool-shed updater
# ============================================================
#
# Purpose:
#   Forward tool and bundle updates to the managed update controller.
#
# Notes:
#   Run with --dry-run to preview installed tool updates.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/.tools/update.sh" "$@"