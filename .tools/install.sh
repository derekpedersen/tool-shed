#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tool installer controller
# ============================================================
#
# Purpose:
#   Dispatch install requests to the appropriate OS-specific logic and
#   keep bundle installs consistent across macOS and Debian-based Linux.
#
# Notes:
#   This script intentionally stays thin; platform-specific logic lives in
#   tools.macos.sh and tools.linux.sh.
# ============================================================

bootstrap_from_github() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to bootstrap installer files from GitHub."
    return 1
  fi

  local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  local ref="${TOOL_SHED_REF:-main}"
  local tmpdir
  local archive
  local extracted_dir
  local rc

  tmpdir="$(mktemp -d)"
  archive="$tmpdir/tool-shed.tar.gz"

  echo "Bootstrapping tool-shed installer from github.com/$repo ($ref)..."
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$archive"
  tar -xzf "$archive" -C "$tmpdir"

  extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/.tools/install.sh" ]]; then
    echo "Bootstrap failed: could not find .tools/install.sh in downloaded archive."
    rm -rf "$tmpdir"
    return 1
  fi

  TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/.tools/install.sh" "$@"
  rc=$?
  rm -rf "$tmpdir"
  return $rc
}

# BASH_SOURCE is unset when piped via curl; fall back to cwd so bootstrap runs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$SCRIPT_DIR/common.sh" || ! -f "$SCRIPT_DIR/module-runtime.sh" || ! -f "$REPO_ROOT/git/install.sh" ]]; then
  if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == "1" ]]; then
    echo "Required installer files are missing from $SCRIPT_DIR and bootstrap already ran."
    exit 1
  fi

  bootstrap_from_github "$@"
  exit $?
fi

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/state.sh"

DRY_RUN=false
args=()
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n)
      DRY_RUN=true
      ;;
    *)
      args+=("$arg")
      ;;
  esac
done

if [[ ${#args[@]} -eq 0 ]]; then
  args=("full")
  echo "No install target provided. Defaulting to: full"
fi

LOG_FILE=""
if [[ "$DRY_RUN" != true ]]; then
  LOG_DIR="${TOOL_SHED_LOG_DIR:-$HOME/.tool-shed/logs}"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
  exec > >(tee -a "$LOG_FILE") 2>&1
  echo "Logging install output to $LOG_FILE"
  echo "Targets: ${args[*]}"
fi

for arg in "${args[@]}"; do
  case "$arg" in
    default|dev|ai-tools)
      echo "Unsupported bundle name: $arg"
      echo "Supported bundles are: full, cloud, services, ai"
      exit 1
      ;;
  esac
done

if [[ " ${args[*]:-} " == *" git-signing "* ]]; then
  if ! printf '%s\n' "${args[@]}" | grep -qx 'gpg'; then
    args+=("gpg")
  fi
fi

if [[ " ${args[*]:-} " == *" identity "* ]]; then
  if ! printf '%s\n' "${args[@]}" | grep -qx 'git-config'; then
    args+=("git-config")
  fi
  if ! printf '%s\n' "${args[@]}" | grep -qx 'git-signing'; then
    args+=("git-signing")
  fi
  if ! printf '%s\n' "${args[@]}" | grep -qx 'ssh-key'; then
    args+=("ssh-key")
  fi
fi

TARGET_LIST=()
while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  TARGET_LIST+=("$target")
done < <(resolve_target_tools "${args[@]}")

PYTHON_PACKAGE_PROFILE="full"
GO_PACKAGE_PROFILE="full"
NODE_PACKAGE_PROFILE="full"
for arg in "${args[@]}"; do
  case "$arg" in
    python-core|python-dev)
      PYTHON_PACKAGE_PROFILE="core"
      ;;
    python-full|python)
      PYTHON_PACKAGE_PROFILE="full"
      ;;
    python-ai)
      PYTHON_PACKAGE_PROFILE="ai"
      ;;
    ai)
      PYTHON_PACKAGE_PROFILE="ai"
      GO_PACKAGE_PROFILE="ai"
      NODE_PACKAGE_PROFILE="full"
      ;;
    go-core|go-dev)
      GO_PACKAGE_PROFILE="core"
      ;;
    go-full|go)
      GO_PACKAGE_PROFILE="full"
      ;;
    go-ai)
      GO_PACKAGE_PROFILE="ai"
      ;;
    node-core|node-dev)
      NODE_PACKAGE_PROFILE="core"
      ;;
    node-full|node)
      NODE_PACKAGE_PROFILE="full"
      ;;
  esac
done

if [[ ${#TARGET_LIST[@]} -eq 0 ]]; then
  echo "No valid installer targets were resolved."
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "DRY RUN: would install the following packages/tools:"
  printf '  - %s\n' "${TARGET_LIST[@]}"
fi

failures=0
for tool in "${TARGET_LIST[@]}"; do
  module_installer="$REPO_ROOT/$tool/install.sh"
  if [[ ! -f "$module_installer" ]]; then
    echo "Missing module installer: $module_installer"
    failures=$((failures + 1))
    continue
  fi

  if ! DRY_RUN="$DRY_RUN" PYTHON_PACKAGE_PROFILE="$PYTHON_PACKAGE_PROFILE" GO_PACKAGE_PROFILE="$GO_PACKAGE_PROFILE" NODE_PACKAGE_PROFILE="$NODE_PACKAGE_PROFILE" TOOL_SHED_OS_OVERRIDE="${TOOL_SHED_OS_OVERRIDE:-}" TOOL_SHED_REPO="${TOOL_SHED_REPO:-}" TOOL_SHED_REF="${TOOL_SHED_REF:-}" bash "$module_installer"; then
    echo "Module install failed: $tool"
    failures=$((failures + 1))
  fi
done

for arg in "${args[@]}"; do
  DRY_RUN="$DRY_RUN" tool_state_record_bundle "$arg"
done

if (( failures > 0 )); then
  echo "Install finished with $failures failure(s)."
  [[ -n "$LOG_FILE" ]] && echo "Full log: $LOG_FILE"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete for: ${TARGET_LIST[*]}"
else
  echo "Install complete for: ${TARGET_LIST[*]}"
  echo "Full log: $LOG_FILE"
fi
