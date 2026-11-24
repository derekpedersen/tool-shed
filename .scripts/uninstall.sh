#!/usr/bin/env bash

# ============================================================
# Tool-shed uninstaller (shell runtime)
# ============================================================
#
# Purpose:
#   Bootstrap and run the shell uninstall flow, with interactive
#   target selection when no explicit target is provided.
#
# Notes:
#   This script is intentionally shell-runtime only.
# ============================================================

set -euo pipefail

usage() {
  echo "Usage: bash uninstall.sh [full|cloud|services|ai|software-developer|data-science|TOOL ...] [--dry-run]"
  echo "Interactive runs can select uninstall targets from installed tools."
  echo "Non-interactive runs require explicit tool or bundle targets."
}

collect_installed_targets() {
  local -a installed=()
  local tool

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    installed+=("$tool")
  done < <(bash "$REPO_ROOT/.tools/list.sh" all 2>/dev/null | awk 'NR > 2 {print $1}')

  if (( ${#installed[@]} > 0 )); then
    printf '%s\n' "${installed[@]}"
  fi
}

prompt_uninstall_targets() {
  local -a installed=()
  local -a selected=()
  local input token pick
  local seen

  while IFS= read -r pick; do
    [[ -n "$pick" ]] || continue
    installed+=("$pick")
  done < <(collect_installed_targets)

  if (( ${#installed[@]} == 0 )); then
    echo "No supported installed tools detected. Provide explicit uninstall targets." >&2
    return 1
  fi

  echo "Installed tools:" > /dev/tty
  for i in "${!installed[@]}"; do
    printf '  %2d) %s\n' "$((i + 1))" "${installed[$i]}" > /dev/tty
  done
  echo "Enter comma-separated numbers, tool names, or 'all'." > /dev/tty
  read -r -u 3 -p "Uninstall targets: " input
  input="${input//,/ }"

  if [[ -z "${input//[[:space:]]/}" ]]; then
    echo "No targets selected." >&2
    return 1
  fi

  for token in $input; do
    if [[ "$token" == "all" ]]; then
      selected=("${installed[@]}")
      break
    fi
    if [[ "$token" =~ ^[0-9]+$ ]]; then
      if (( token >= 1 && token <= ${#installed[@]} )); then
        selected+=("${installed[$((token - 1))]}")
        continue
      fi
      echo "Ignoring out-of-range selection: $token" > /dev/tty
      continue
    fi
    selected+=("$token")
  done

  if (( ${#selected[@]} == 0 )); then
    echo "No valid uninstall targets selected." >&2
    return 1
  fi

  local -a deduped=()
  for pick in "${selected[@]}"; do
    seen=false
    for existing in "${deduped[@]}"; do
      if [[ "$existing" == "$pick" ]]; then
        seen=true
        break
      fi
    done
    if [[ "$seen" == false ]]; then
      deduped+=("$pick")
    fi
  done

  printf '%s\n' "${deduped[@]}"
}

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"

HAS_TTY=false
if [[ -r /dev/tty && -w /dev/tty ]]; then
  HAS_TTY=true
  exec 3<>/dev/tty
fi

targets=()
options=()
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n|--verbose|-v)
      options+=("$arg")
      ;;
    --help|-h) usage; exit 0 ;;
    -*)
      options+=("$arg")
      ;;
    *) targets+=("$arg") ;;
  esac
done

if [[ ${#targets[@]} -eq 0 ]]; then
  if [[ "$HAS_TTY" == true && "${TOOL_SHED_NO_PROMPT:-0}" != "1" ]]; then
    if ! mapfile -t targets < <(prompt_uninstall_targets); then
      usage >&2
      exit 2
    fi
  else
    echo "An explicit uninstall target is required for non-interactive runs." >&2
    usage >&2
    exit 2
  fi
fi
if [[ -f "$REPO_ROOT/.tools/uninstall.sh" ]]; then
  exec bash "$REPO_ROOT/.tools/uninstall.sh" "${options[@]}" "${targets[@]}"
fi

tool_shed_require_not_bootstrapped

tool_shed_bootstrap_script "uninstall.sh" "${options[@]}" "${targets[@]}"
