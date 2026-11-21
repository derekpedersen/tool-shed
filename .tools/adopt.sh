#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Managed tool adoption helper
# ============================================================
#
# Purpose:
#   Discover unmanaged installed tools and opt them into the repo's
#   managed state without duplicating prompt logic across scripts.
#
# Notes:
#   Prompt mode defaults to a safe no. Non-interactive runs skip prompts
#   unless TOOL_SHED_FORCE_PROMPT=1 is set.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: bash .tools/adopt.sh [--prompt] [TOOL ...]"
  echo "Adopt installed but unmanaged tools into the managed state."
  echo "  --prompt   Ask for confirmation before adopting detected tools"
  echo "  TOOL ...   Explicit tool names to adopt; otherwise adopts all unmanaged tools"
}

prompt_yes_no() {
  local prompt="${1:-Continue?}"
  local default="${2:-n}"
  local answer=""

  if [[ "${TOOL_SHED_NO_PROMPT:-0}" == "1" ]]; then
    return 1
  fi

  if [[ ! -t 0 && "${TOOL_SHED_FORCE_PROMPT:-0}" != "1" ]]; then
    return 1
  fi

  if [[ "$default" == "y" ]]; then
    read -r -p "$prompt [Y/n]: " answer
    answer="${answer:-Y}"
  else
    read -r -p "$prompt [y/N]: " answer
    answer="${answer:-N}"
  fi

  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

collect_unmanaged_tools() {
  local tool
  local -a detected=()

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    [[ "$tool" == "TOOL" ]] && continue
    detected+=("$tool")
  done < <(bash "$SCRIPT_DIR/list.sh" 2>/dev/null | awk '$3 == "unmanaged" {print $1}')

  if (( ${#detected[@]} > 0 )); then
    printf '%s\n' "${detected[@]}"
  fi
}

prompt_mode=false
args=()
for arg in "$@"; do
  case "$arg" in
    --prompt) prompt_mode=true ;;
    --help|-h) usage; exit 0 ;;
    --dry-run|-n) ;; 
    --yes|-y) ;; 
    -*) echo "Unsupported option: $arg" >&2; usage >&2; exit 2 ;;
    *) args+=("$arg") ;;
  esac
done

if [[ ${#args[@]} -gt 0 ]]; then
  selected=()
  for arg in "${args[@]}"; do
    if [[ "$arg" == "all" ]]; then
      while IFS= read -r tool; do
        [[ -n "$tool" ]] || selected+=("$tool")
      done < <(collect_unmanaged_tools)
      continue
    fi
    selected+=("$arg")
  done
else
  selected=()
  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    selected+=("$tool")
  done < <(collect_unmanaged_tools)
fi

if (( ${#selected[@]} == 0 )); then
  echo "No unmanaged installed tools detected."
  exit 0
fi

if [[ "$prompt_mode" == true ]]; then
  echo "Detected unmanaged installed tools: ${selected[*]}."
  if ! prompt_yes_no "Adopt them as managed now?" "n"; then
    echo "Leaving unmanaged tools alone."
    exit 0
  fi
fi

bash "$SCRIPT_DIR/update.sh" --adopt "${selected[@]}"
