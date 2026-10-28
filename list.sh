#!/usr/bin/env bash

# ============================================================
# Tool-shed inventory command
# ============================================================
#
# Purpose:
#   Bootstrap and run the standalone installed-tool inventory.
#
# Notes:
#   Inventory is read-only; a remote invocation downloads the repository first.
# ============================================================

set -euo pipefail

bootstrap_from_github() {
  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "curl and tar are required to bootstrap the tool-shed inventory." >&2
    return 1
  fi

  local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  local ref="${TOOL_SHED_REF:-main}"
  local extracted_dir rc
  BOOTSTRAP_TMPDIR="$(mktemp -d)" || return 1
  trap '[[ -z "${BOOTSTRAP_TMPDIR:-}" ]] || rm -rf "$BOOTSTRAP_TMPDIR"' EXIT

  echo "Downloading tool-shed inventory from github.com/$repo ($ref)..." >&2
  if ! curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$BOOTSTRAP_TMPDIR/tool-shed.tar.gz"; then
    echo "Could not download tool-shed repository archive." >&2
    return 1
  fi
  if ! tar -xzf "$BOOTSTRAP_TMPDIR/tool-shed.tar.gz" -C "$BOOTSTRAP_TMPDIR"; then
    echo "Could not extract tool-shed repository archive." >&2
    return 1
  fi
  extracted_dir="$(find "$BOOTSTRAP_TMPDIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print -quit)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/.tools/list.sh" ]]; then
    echo "Downloaded archive does not contain .tools/list.sh." >&2
    return 1
  fi

  rc=0
  TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/list.sh" "$@" || rc=$?
  rm -rf "$BOOTSTRAP_TMPDIR"
  BOOTSTRAP_TMPDIR=""
  return "$rc"
}

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || pwd)"
if [[ -f "$SCRIPT_DIR/.tools/list.sh" ]]; then
  exec bash "$SCRIPT_DIR/.tools/list.sh" "$@"
fi

if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == 1 ]]; then
  echo "Required inventory files are missing after bootstrap." >&2
  exit 1
fi

bootstrap_from_github "$@"