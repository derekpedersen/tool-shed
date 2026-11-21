#!/usr/bin/env bash

# ============================================================
# Root installer prompt (shell runtime)
# ============================================================
#
# Purpose:
#   Provide a simple interactive shell-runtime entrypoint that asks whether
#   to run bash helper installation and tool installation.
#
# Notes:
#   This script is intentionally shell-runtime only.
# ============================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$REPO_ROOT/.bash/install.sh" || ! -f "$REPO_ROOT/.tools/install.sh" ]]; then
  if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == "1" ]]; then
    echo "Required installer files are missing from $REPO_ROOT and bootstrap already ran."
    exit 1
  fi

  tool_shed_bootstrap_script "install.sh" "$@"
  exit $?
fi

HAS_TTY=false
if [[ -r /dev/tty && -w /dev/tty ]]; then
  HAS_TTY=true
fi

confirm() {
  local prompt="$1"
  local default="${2:-y}"
  local answer

  if [[ "${TOOL_SHED_NO_PROMPT:-0}" == "1" ]]; then
    [[ "$default" == "y" ]]
    return
  fi

  if [[ "$HAS_TTY" != true ]]; then
    if [[ "${TOOL_SHED_FORCE_PROMPT:-0}" == "1" ]]; then
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
    fi
    [[ "$default" == "y" ]]
    return
  fi

  if [[ "$default" == "y" ]]; then
    read -r -u 3 -p "$prompt [Y/n]: " answer
    answer="${answer:-Y}"
  else
    read -r -u 3 -p "$prompt [y/N]: " answer
    answer="${answer:-N}"
  fi

  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_adopt_unmanaged_tools() {
  local tool
  local -a unmanaged=()

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    [[ "$tool" == "TOOL" ]] && continue
    unmanaged+=("$tool")
  done < <(bash "$REPO_ROOT/.tools/list.sh" 2>/dev/null | awk '$3 == "unmanaged" {print $1}')

  if (( ${#unmanaged[@]} == 0 )); then
    return 0
  fi

  if [[ "$HAS_TTY" != true && "${TOOL_SHED_FORCE_PROMPT:-0}" != "1" ]]; then
    return 0
  fi

  echo "Detected unmanaged installed tools: ${unmanaged[*]}." > /dev/tty
  if confirm "Adopt them as managed now?" "n"; then
    bash "$REPO_ROOT/.tools/update.sh" --adopt "${unmanaged[@]}"
  fi
}

pick_tools_target() {
  local target="${1:-full}"
  local mode=""

  if [[ "$HAS_TTY" != true ]]; then
    printf '%s\n' "$target"
    return
  fi

  echo "Tools install mode:" > /dev/tty
  echo "  1) full (default)" > /dev/tty
  echo "  2) software-developer" > /dev/tty
  echo "  3) data-science" > /dev/tty
  echo "  4) cloud" > /dev/tty
  echo "  5) services" > /dev/tty
  echo "  6) ai" > /dev/tty
  echo "  7) Prompt by language" > /dev/tty
  read -r -u 3 -p "Mode [1]: " mode
  mode="${mode:-1}"

  case "$mode" in
    1) printf '%s\n' "full" ;;
    2) printf '%s\n' "software-developer" ;;
    3) printf '%s\n' "data-science" ;;
    4) printf '%s\n' "cloud" ;;
    5) printf '%s\n' "services" ;;
    6) printf '%s\n' "ai" ;;
    7) pick_language_targets ;;
    *) echo "Unknown mode: $mode. Falling back to full target." > /dev/tty; printf '%s\n' "full" ;;
  esac
}

pick_language_targets() {
  local py_profile="skip"
  local go_profile="skip"
  local node_profile="skip"
  local selected_any=false

  if confirm "Install Python language tools?" "y"; then
    py_profile="$(pick_package_set "Python")"
    selected_any=true
  fi

  if confirm "Install Go language tools?" "y"; then
    go_profile="$(pick_package_set "Go")"
    selected_any=true
  fi

  if confirm "Install Node language tools?" "y"; then
    node_profile="$(pick_package_set "Node")"
    selected_any=true
  fi

  if [[ "$selected_any" != true ]]; then
    echo "No language tools selected. Installing base non-language tool set." > /dev/tty
  fi

  local targets=(
    git
    curl
    wget
    unzip
    nvm
    kubectl
    helm
    docker
    dotnetcore
    vscode
  )

  case "$py_profile" in
    all) targets+=("python-full") ;;
    ai) targets+=("python-ai") ;;
  esac

  case "$go_profile" in
    all) targets+=("go-full") ;;
    ai) targets+=("go-ai") ;;
  esac

  case "$node_profile" in
    all|ai) targets+=("node-full") ;;
  esac

  printf '%s\n' "${targets[*]}"
}

pick_package_set() {
  local language="$1"
  local input

  read -r -u 3 -p "$language package set (all/ai) [all]: " input
  input="${input:-all}"

  if [[ "$input" == "all" || "$input" == "ai" ]]; then
    printf '%s\n' "$input"
    return
  fi

  echo "Unknown package set '$input' for $language. Using all." > /dev/tty
  printf '%s\n' "all"
}

if [[ "$HAS_TTY" == true ]]; then
  exec 3<>/dev/tty
fi

run_bash=false
run_tools=false
tools_target="${1:-full}"

if confirm "Run bash helper install?" "y"; then
  run_bash=true
fi

if confirm "Run tools install?" "y"; then
  run_tools=true
  tools_target="$(pick_tools_target "$tools_target")"
fi

if [[ "$run_bash" == false && "$run_tools" == false ]]; then
  echo "Nothing selected. Exiting."
  exit 0
fi

if [[ "$run_bash" == true ]]; then
  bash "$REPO_ROOT/.bash/install.sh"
fi

if [[ "$run_tools" == true ]]; then
  read -r -a tool_args <<< "$tools_target"
  bash "$REPO_ROOT/.tools/install.sh" "${tool_args[@]}"
fi

prompt_adopt_unmanaged_tools

echo "Root install flow complete."

if [[ "$HAS_TTY" == true ]]; then
  exec 3>&-
fi
