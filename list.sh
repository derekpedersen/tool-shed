#!/usr/bin/env bash

# ============================================================
# Root runtime selector (list)
# ============================================================
#
# Purpose:
#   Prompt for runtime selection and dispatch list to shell or Go.
# ============================================================

set -euo pipefail

bootstrap_from_github() {
  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "curl and tar are required to bootstrap tool-shed." >&2
    return 1
  fi

  local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  local ref="${TOOL_SHED_REF:-main}"
  local extracted_dir rc tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$tmpdir/tool-shed.tar.gz"
  tar -xzf "$tmpdir/tool-shed.tar.gz" -C "$tmpdir"
  extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/list.sh" ]]; then
    echo "Bootstrap failed: list.sh not found in downloaded archive." >&2
    return 1
  fi

  rc=0
  TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/list.sh" "$@" || rc=$?
  return "$rc"
}

choose_runtime() {
  local current="$1"
  if [[ -n "$current" ]]; then
    printf '%s\n' "$current"
    return
  fi
  if [[ "${TOOL_SHED_NO_PROMPT:-0}" == "1" ]]; then
    printf '%s\n' "shell"
    return
  fi
  if [[ -r /dev/tty && -w /dev/tty ]]; then
    local input
    echo "Select runtime for list:" > /dev/tty
    echo "  1) shell (default)" > /dev/tty
    echo "  2) go" > /dev/tty
    read -r -u 3 -p "Runtime [1]: " input
    case "${input:-1}" in
      2|go) printf '%s\n' "go" ;;
      *) printf '%s\n' "shell" ;;
    esac
    return
  fi
  printf '%s\n' "shell"
}

resolve_runtime_binary() {
  if [[ -n "${TOOL_SHED_BINARY:-}" && -x "${TOOL_SHED_BINARY}" ]]; then
    printf '%s\n' "${TOOL_SHED_BINARY}"
    return 0
  fi
  if [[ -x "$SCRIPT_DIR/.bin/tool-shed/tool-shed-local" ]]; then
    printf '%s\n' "$SCRIPT_DIR/.bin/tool-shed/tool-shed-local"
    return 0
  fi
  if command -v tool-shed >/dev/null 2>&1; then
    command -v tool-shed
    return 0
  fi
  return 1
}

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SHELL_SCRIPT="$SCRIPT_DIR/.scripts/list.sh"

if [[ ! -f "$SHELL_SCRIPT" ]]; then
  if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == "1" ]]; then
    echo "Required runtime selector files are missing after bootstrap." >&2
    exit 1
  fi
  bootstrap_from_github "$@"
  exit $?
fi

if [[ -r /dev/tty && -w /dev/tty ]]; then
  exec 3<>/dev/tty
fi

runtime="${TOOL_SHED_RUNTIME:-}"
backend="${TOOL_SHED_BACKEND:-shell}"
passthrough=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime)
      runtime="$2"
      shift 2
      ;;
    --runtime=*)
      runtime="${1#--runtime=}"
      shift
      ;;
    --backend)
      backend="$2"
      shift 2
      ;;
    --backend=*)
      backend="${1#--backend=}"
      shift
      ;;
    *)
      passthrough+=("$1")
      shift
      ;;
  esac
done

runtime="$(choose_runtime "$runtime")"

if [[ "$runtime" != "shell" && "$runtime" != "go" ]]; then
  echo "Invalid runtime: $runtime (expected shell or go)" >&2
  exit 2
fi

if [[ "$runtime" == "go" ]]; then
  if bin="$(resolve_runtime_binary)"; then
    exec "$bin" --runtime go --backend "$backend" list "${passthrough[@]}"
  fi
  echo "Go runtime requested but no tool-shed binary found; falling back to shell runtime." >&2
fi

exec bash "$SHELL_SCRIPT" "${passthrough[@]}"
