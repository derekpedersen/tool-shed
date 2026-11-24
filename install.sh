#!/usr/bin/env bash

# ============================================================
# Root runtime selector (install)
# ============================================================
#
# Purpose:
#   Resolve runtime selection first, then dispatch install to shell or Go.
#   This keeps local and curl-bootstrap runs behaviorally aligned.
# ============================================================

set -euo pipefail

bootstrap_shell_runtime() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to bootstrap tool-shed shell runtime." >&2
    return 1
  fi

  local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  local ref="${TOOL_SHED_REF:-main}"
  local raw_base="https://raw.githubusercontent.com/$repo/$ref"
  local tmpdir rc

  tmpdir="$(mktemp -d)"
  mkdir -p "$tmpdir/.scripts"

  echo "Fetching shell runtime for install from github.com/$repo ($ref)..." >&2
  curl -fsSL "$raw_base/.scripts/common.sh" -o "$tmpdir/.scripts/common.sh"
  curl -fsSL "$raw_base/.scripts/install.sh" -o "$tmpdir/.scripts/install.sh"

  rc=0
  TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$tmpdir/.scripts/install.sh" "$@" || rc=$?
  rm -rf "$tmpdir"
  return "$rc"
}

resolve_platform_target() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *) return 1 ;;
  esac

  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    armv5l|armv5) arch="armv5" ;;
    armv7l|armv7) arch="armv7" ;;
    armv6l|armv6) arch="armv6" ;;
    i386|i686) arch="386" ;;
    riscv64) arch="riscv64" ;;
    *) return 1 ;;
  esac

  printf '%s\n' "$os-$arch"
}

download_runtime_binary() {
  local force_refresh="${1:-0}"
  if [[ "${TOOL_SHED_AUTO_DOWNLOAD_BINARY:-1}" != "1" ]]; then
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi

  local target repo ref base name cache_dir cache_path
  target="$(resolve_platform_target)" || return 1
  repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  ref="${TOOL_SHED_REF:-main}"
  base="https://raw.githubusercontent.com/$repo/$ref/.bin/tool-shed"
  name="tool-shed-$target"
  if [[ "$target" == windows-* ]]; then
    name="$name.exe"
  fi

  cache_dir="${TOOL_SHED_CACHE_DIR:-$HOME/.tool-shed/bin}"
  cache_path="$cache_dir/$name"

  mkdir -p "$cache_dir"
  if [[ "$force_refresh" == "1" || ! -x "$cache_path" ]]; then
    echo "Downloading tool-shed binary for $target from github.com/$repo ($ref)..." >&2
    curl -fsSL "$base/$name" -o "$cache_path" || return 1
    chmod +x "$cache_path" || return 1
  fi

  printf '%s\n' "$cache_path"
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
    echo "Select runtime for install:" > /dev/tty
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
  if bin_path="$(download_runtime_binary)"; then
    printf '%s\n' "$bin_path"
    return 0
  fi
  return 1
}

go_binary_supports_runtime_flags() {
  local candidate="$1"
  local help_text
  help_text="$("$candidate" --help 2>&1 || true)"
  grep -q -- '--runtime' <<< "$help_text"
}

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SHELL_SCRIPT="$SCRIPT_DIR/.scripts/install.sh"

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
    if go_binary_supports_runtime_flags "$bin"; then
      exec "$bin" --runtime go --backend "$backend" install "${passthrough[@]}"
    fi

    # Try to refresh the cached binary once before using compatibility fallback.
    if [[ -z "${TOOL_SHED_BINARY:-}" ]]; then
      if refreshed_bin="$(download_runtime_binary 1 2>/dev/null)"; then
        if go_binary_supports_runtime_flags "$refreshed_bin"; then
          exec "$refreshed_bin" --runtime go --backend "$backend" install "${passthrough[@]}"
        fi
      fi
    fi

    TOOL_SHED_RUNTIME=go TOOL_SHED_BACKEND="$backend" exec "$bin" install "${passthrough[@]}"
  fi
  echo "Go runtime requested but no tool-shed binary found; falling back to shell runtime." >&2
fi

# Pick runtime first so bootstrap runs follow the same runtime decision path.
if [[ ! -f "$SHELL_SCRIPT" ]]; then
  bootstrap_shell_runtime "${passthrough[@]}"
  exit $?
fi

exec bash "$SHELL_SCRIPT" "${passthrough[@]}"
