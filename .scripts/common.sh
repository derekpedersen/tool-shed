#!/usr/bin/env bash

# ============================================================
# .scripts common helpers
# ============================================================
#
# Purpose:
#   Keep shell-only root wrapper behavior centralized and consistent.
# ============================================================

set -euo pipefail

tool_shed_bootstrap_script() {
  local script_name="$1"
  shift

  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "curl and tar are required to bootstrap tool-shed scripts." >&2
    return 1
  fi

  local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  local ref="${TOOL_SHED_REF:-main}"
  local extracted_dir rc tmpdir

  tmpdir="$(mktemp -d)" || return 1
  trap '[[ -n "${tmpdir:-}" ]] && rm -rf "$tmpdir"' EXIT

  echo "Downloading tool-shed script from github.com/$repo ($ref)..." >&2
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$tmpdir/tool-shed.tar.gz"
  tar -xzf "$tmpdir/tool-shed.tar.gz" -C "$tmpdir"

  extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print -quit)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/.scripts/$script_name" ]]; then
    echo "Downloaded archive does not contain .scripts/$script_name." >&2
    return 1
  fi

  rc=0
  TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/.scripts/$script_name" "$@" || rc=$?
  return "$rc"
}

tool_shed_require_not_bootstrapped() {
  if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == "1" ]]; then
    echo "Required script files are missing after bootstrap." >&2
    exit 1
  fi
}
