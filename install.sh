#!/usr/bin/env bash

# ============================================================
# Root installer prompt
# ============================================================
#
# Purpose:
#   Provide a simple interactive entrypoint that asks whether to run
#   bash helper installation and tool installation.
#
# Notes:
#   Delegates to .bash/install.sh and .tools/install.sh to preserve
#   existing install behavior.
# ============================================================

set -euo pipefail

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

  echo "Bootstrapping tool-shed root installer from github.com/$repo ($ref)..."
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$archive"
  tar -xzf "$archive" -C "$tmpdir"

  extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/install.sh" ]]; then
    echo "Bootstrap failed: could not find install.sh in downloaded archive."
    rm -rf "$tmpdir"
    return 1
  fi

  TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/install.sh" "$@"
  rc=$?
  rm -rf "$tmpdir"
  return $rc
}

# BASH_SOURCE can be unavailable when piped via curl; use $0 as a fallback.
SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/.bash/install.sh" || ! -f "$SCRIPT_DIR/.tools/install.sh" ]]; then
  if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == "1" ]]; then
    echo "Required installer files are missing from $SCRIPT_DIR and bootstrap already ran."
    exit 1
  fi

  bootstrap_from_github "$@"
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
  done < <(bash "$SCRIPT_DIR/.tools/list.sh" 2>/dev/null | awk '$3 == "unmanaged" {print $1}')

  if (( ${#unmanaged[@]} == 0 )); then
    return 0
  fi

  if [[ "$HAS_TTY" != true && "${TOOL_SHED_FORCE_PROMPT:-0}" != "1" ]]; then
    return 0
  fi

  echo "Detected unmanaged installed tools: ${unmanaged[*]}." > /dev/tty
  if confirm "Adopt them as managed now?" "n"; then
    bash "$SCRIPT_DIR/.tools/update.sh" --adopt "${unmanaged[@]}"
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
  echo "  2) cloud" > /dev/tty
  echo "  3) services" > /dev/tty
  echo "  4) ai" > /dev/tty
  echo "  5) Prompt by language" > /dev/tty
  read -r -u 3 -p "Mode [1]: " mode
  mode="${mode:-1}"

  case "$mode" in
    1)
      printf '%s\n' "full"
      return
      ;;
    2)
      printf '%s\n' "cloud"
      return
      ;;
    3)
      printf '%s\n' "services"
      return
      ;;
    4)
      printf '%s\n' "ai"
      return
      ;;
    5)
      pick_language_targets
      return
      ;;
    *)
      echo "Unknown mode: $mode. Falling back to full target." > /dev/tty
      printf '%s\n' "full"
      return
      ;;
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
    skip) ;;
  esac

  case "$go_profile" in
    all) targets+=("go-full") ;;
    ai) targets+=("go-ai") ;;
    skip) ;;
  esac

  case "$node_profile" in
    all|ai) targets+=("node-full") ;;
    skip) ;;
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
  bash "$SCRIPT_DIR/.bash/install.sh"
fi

if [[ "$run_tools" == true ]]; then
  # Split user input into words so multiple targets are supported.
  read -r -a tool_args <<< "$tools_target"
  bash "$SCRIPT_DIR/.tools/install.sh" "${tool_args[@]}"
fi

prompt_adopt_unmanaged_tools

echo "Root install flow complete."

if [[ "$HAS_TTY" == true ]]; then
  exec 3>&-
fi