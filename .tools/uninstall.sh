#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tool installer uninstaller
# ============================================================
#
# Purpose:
#   Reverse the repo's managed tool installation flow for explicit tool or
#   bundle names without touching unrelated system state.
#
# Notes:
#   This script intentionally mirrors the install pattern: explicit targets,
#   bundle support, and dry-run safety. It only removes tools managed by this
#   repository or simple package-manager installs.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
if [[ ! -f "$SCRIPT_DIR/common.sh" || ! -f "$SCRIPT_DIR/windows.sh" ]]; then
  echo "Required installer files missing: $SCRIPT_DIR/common.sh and $SCRIPT_DIR/windows.sh"
  exit 1
fi

source "$SCRIPT_DIR/common.sh"

OS="${TOOL_SHED_OS_OVERRIDE:-$(uname -s)}"
case "$OS" in
  Darwin|Linux)
    PLATFORM="unix"
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    source "$SCRIPT_DIR/windows.sh"
    PLATFORM="windows"
    ;;
  *)
    if [[ -n "${WSL_DISTRO_NAME:-}" || "$(uname -r 2>/dev/null || true)" == *Microsoft* ]]; then
      PLATFORM="unix"
    else
      echo "Unsupported OS: $OS"
      exit 1
    fi
    ;;
esac

usage() {
  cat <<'EOF'
Usage: bash ./.tools/uninstall.sh [full|cloud|services|ai|<tool> [tool ...]] [--dry-run]

Bundle targets:
  full  = base tools + cloud CLIs + data/service tools
  cloud = base tools + kubernetes/docker/cloud CLIs + jq/yq
  services = local data/service tools only
  ai    = base tools (including R, Java, Scala, C/C++, and Rust) + AI package profiles for python/go/node

Canonical tools:
  git, gpg, curl, wget, unzip, python3, r, nvm, node, golang, cpp, rust, java, scala, kubectl, helm, docker,
  dotnetcore, vscode, gcloud, aws, eksctl, az, doctl, jq, yq, postgres, redis,
  mysql, clickhouse, mongodb, rabbitmq, elasticsearch, kafka, git-config,
  git-signing, ssh-key, identity

Legacy aliases (supported):
  kubernetes-cli->kubectl, google-cloud->gcloud, awscli->aws,
  azure|azure-cli->az, digitalocean|doks->doctl, dotnet->dotnetcore, code->vscode,
  jdk->java, rustup->rust, c++->cpp, scala-cli->scala, R|r-lang->r

Use canonical names in scripts and examples.

Examples:
  bash ./.tools/uninstall.sh full
  bash ./.tools/uninstall.sh services
  bash ./.tools/uninstall.sh kubectl docker --dry-run
  bash ./.tools/uninstall.sh ai
EOF
}

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
  echo "No uninstall target provided. Defaulting to: full"
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

INTERNAL_MODE="${TOOLS_UNINSTALL_MODULE_INTERNAL:-0}"

expand_bundle() {
  local item="$1"
  case "$item" in
    full)
      printf '%s\n' "${FULL_BUNDLE[@]}"
      ;;
    cloud)
      printf '%s\n' "${CLOUD_BUNDLE[@]}"
      ;;
    services)
      printf '%s\n' "${SERVICES_BUNDLE[@]}"
      ;;
    ai)
      printf '%s\n' "${AI_BUNDLE[@]}"
      ;;
    *)
      printf '%s\n' "$item"
      ;;
  esac
}

resolve_targets() {
  local expanded=()
  local item
  for item in "$@"; do
    while IFS= read -r expanded_item; do
      [[ -z "$expanded_item" ]] && continue
      expanded+=("$expanded_item")
    done < <(expand_bundle "$item")
  done

  local result=()
  for item in "${expanded[@]}"; do
    local seen_item
    local already_seen=false
    if [[ ${#result[@]} -gt 0 ]]; then
      for seen_item in "${result[@]}"; do
        if [[ "$seen_item" == "$item" ]]; then
          already_seen=true
          break
        fi
      done
    fi

    if [[ "$already_seen" == false ]]; then
      result+=("$item")
    fi
  done

  if [[ ${#result[@]} -gt 0 ]]; then
    printf '%s\n' "${result[@]}"
  fi
}

remove_git_identity_config() {
  if git config --global --get user.name >/dev/null 2>&1; then
    git config --global --unset-all user.name || true
  fi
  if git config --global --get user.email >/dev/null 2>&1; then
    git config --global --unset-all user.email || true
  fi
}

remove_git_signing_config() {
  git config --global --unset-all commit.gpgsign || true
  git config --global --unset-all tag.gpgSign || true
  git config --global --unset-all gpg.program || true
  git config --global --unset-all user.signingkey || true
}

remove_ssh_key() {
  local key_path="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
  rm -f "$key_path" "$key_path.pub"
}

remove_apt_package() {
  local pkg="$1"
  local binary_name="${2:-$1}"
  local sudo_cmd=""

  if command -v sudo >/dev/null 2>&1 && [[ "$(id -u)" != "0" ]]; then
    sudo_cmd="sudo"
  fi

  if ! dpkg -s "$pkg" >/dev/null 2>&1 && ! command -v "$binary_name" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ -n "$sudo_cmd" ]]; then
      echo "DRY RUN: $sudo_cmd apt-get purge -y $pkg"
    else
      echo "DRY RUN: apt-get purge -y $pkg"
    fi
    return 0
  fi

  if [[ -n "$sudo_cmd" ]]; then
    $sudo_cmd apt-get purge -y "$pkg"
  else
    apt-get purge -y "$pkg"
  fi
}

remove_binary() {
  local binary="$1"
  local path
  path="$(command -v "$binary" 2>/dev/null || true)"

  if [[ -z "$path" ]]; then
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: rm -f $path"
    return 0
  fi

  rm -f "$path"
}

remove_homebrew_package() {
  local pkg="$1"
  if ! command -v brew >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: brew uninstall --force $pkg"
    return 0
  fi

  brew uninstall --force "$pkg" || true
}

remove_homebrew_cask() {
  local pkg="$1"

  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: brew uninstall --cask --force $pkg"
    return 0
  fi

  if ! command -v brew >/dev/null 2>&1 || ! brew list --cask --versions "$pkg" >/dev/null 2>&1; then
    return 0
  fi

  brew uninstall --cask --force "$pkg" || true
}

uninstall_tool() {
  local tool="$1"

  case "$tool" in
    git)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "git" "git"
      fi
      ;;
    gpg)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "gnupg" "gpg"
      fi
      ;;
    curl)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "curl" "curl"
      fi
      ;;
    wget)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "wget" "wget"
      fi
      ;;
    unzip)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "unzip" "unzip"
      fi
      ;;
    python3)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "python3" "python3"
      fi
      ;;
    git-config)
      if [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN: would clear global Git identity config"
      else
        remove_git_identity_config
      fi
      ;;
    git-signing)
      if [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN: would clear Git signing config"
      else
        remove_git_signing_config
      fi
      ;;
    ssh-key)
      if [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN: would remove SSH key at ${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
      else
        remove_ssh_key
      fi
      ;;
    identity)
      if [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN: would clear Git identity, signing, and SSH key config"
      else
        remove_git_identity_config
        remove_git_signing_config
        remove_ssh_key
      fi
      ;;
    nvm)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      elif [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN: would remove $HOME/.nvm"
      else
        rm -rf "$HOME/.nvm"
      fi
      ;;
    node)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      elif [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN: would remove node and nvm-managed Node installs"
      else
        rm -rf "$HOME/.nvm"
      fi
      ;;
    golang)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_binary "go"
        if [[ -d "/usr/local/go" ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            echo "DRY RUN: would remove /usr/local/go"
          else
            rm -rf /usr/local/go
          fi
        fi
      fi
      ;;
    java)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      elif [[ "$OS" == "Darwin" ]]; then
        remove_homebrew_cask "temurin@25"
      else
        remove_apt_package "temurin-25-jdk" "temurin-25-jdk"
      fi
      ;;
    cpp)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      elif [[ "$OS" == "Darwin" ]]; then
        echo "Apple Command Line Tools are system-managed and were left installed."
      else
        remove_apt_package "build-essential" "build-essential"
      fi
      ;;
    rust)
      echo "Rustup, Rust toolchains, and Cargo data are user-managed and were left intact."
      ;;
    scala)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      elif command -v scala-cli >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == true ]]; then
          echo "DRY RUN: scala-cli uninstall"
        else
          scala-cli uninstall
        fi
      fi
      ;;
    r)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      elif [[ "$OS" == "Darwin" ]]; then
        remove_homebrew_package "r"
      else
        remove_apt_package "r-base" "R"
      fi
      ;;
    helm)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_binary "helm"
        if [[ -f "/usr/local/bin/helm" ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            echo "DRY RUN: would remove /usr/local/bin/helm"
          else
            rm -f /usr/local/bin/helm
          fi
        fi
      fi
      ;;
    kubectl|kubernetes-cli)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_binary "kubectl"
        if [[ -f "/usr/local/bin/kubectl" ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            echo "DRY RUN: would remove /usr/local/bin/kubectl"
          else
            rm -f /usr/local/bin/kubectl
          fi
        fi
      fi
      ;;
    docker)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "docker-ce" "docker"
        remove_apt_package "docker-ce-cli" "docker"
        remove_apt_package "containerd.io" "containerd"
        remove_apt_package "docker-buildx-plugin" "docker-buildx"
        remove_apt_package "docker-compose-plugin" "docker-compose"
      fi
      ;;
    dotnetcore|dotnet)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "dotnet-sdk-8.0" "dotnet"
        remove_binary "dotnet"
      fi
      ;;
    vscode|code)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "code" "code"
        remove_binary "code"
      fi
      ;;
    gcloud|google-cloud)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "google-cloud-cli" "gcloud"
        remove_binary "gcloud"
      fi
      ;;
    aws|awscli)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "awscli" "aws"
        remove_binary "aws"
      fi
      ;;
    eksctl)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_binary "eksctl"
      fi
      ;;
    az|azure|azure-cli)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "azure-cli" "az"
        remove_binary "az"
      fi
      ;;
    doctl|digitalocean|doks)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_binary "doctl"
      fi
      ;;
    jq)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "jq" "jq"
      fi
      ;;
    yq)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_binary "yq"
      fi
      ;;
    postgres)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "postgresql" "psql"
      fi
      ;;
    redis)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "redis-server" "redis-server"
      fi
      ;;
    mysql)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "mysql-server" "mysqld"
      fi
      ;;
    clickhouse)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "clickhouse-server" "clickhouse-server"
      fi
      ;;
    mongodb)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "mongodb-org" "mongod"
        local mongodb_file
        for mongodb_file in \
          /etc/apt/sources.list.d/mongodb-org-7.0.list \
          /etc/apt/sources.list.d/mongodb-org-8.0.list \
          /usr/share/keyrings/mongodb-server-7.0.gpg \
          /usr/share/keyrings/mongodb-server-8.0.gpg; do
          [[ -f "$mongodb_file" ]] || continue
          if [[ "$DRY_RUN" == true ]]; then
            echo "DRY RUN: sudo rm -f $mongodb_file"
          else
            sudo rm -f "$mongodb_file"
          fi
        done
      fi
      ;;
    rabbitmq)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "rabbitmq-server" "rabbitmq-server"
      fi
      ;;
    elasticsearch)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "elasticsearch" "elasticsearch"
      fi
      ;;
    kafka)
      if [[ "$PLATFORM" == "windows" ]]; then
        uninstall_windows "$tool"
      else
        remove_apt_package "kafka" "kafka"
      fi
      ;;
    *)
      echo "Unsupported tool: $tool"
      ;;
  esac
}

TARGET_LIST=()
if [[ "$INTERNAL_MODE" == "1" ]]; then
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    TARGET_LIST+=("$(canonical_tool_name "$target")")
  done < <(printf '%s\n' "${args[@]}")
else
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    TARGET_LIST+=("$target")
  done < <(resolve_target_tools "${args[@]}")
fi

if [[ ${#TARGET_LIST[@]} -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "$INTERNAL_MODE" == "1" ]]; then
  for tool in "${TARGET_LIST[@]}"; do
    uninstall_tool "$tool"
  done
  echo "Internal uninstall complete for: ${TARGET_LIST[*]}"
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "DRY RUN: would uninstall the following tools:"
  printf '  - %s\n' "${TARGET_LIST[@]}"
fi

failures=0
for tool in "${TARGET_LIST[@]}"; do
  module_uninstaller="$REPO_ROOT/$tool/uninstall.sh"
  if [[ ! -f "$module_uninstaller" ]]; then
    echo "Missing module uninstaller: $module_uninstaller"
    failures=$((failures + 1))
    continue
  fi

  if ! DRY_RUN="$DRY_RUN" TOOL_SHED_OS_OVERRIDE="${TOOL_SHED_OS_OVERRIDE:-}" bash "$module_uninstaller"; then
    echo "Module uninstall failed: $tool"
    failures=$((failures + 1))
  fi
done

if (( failures > 0 )); then
  echo "Uninstall finished with $failures failure(s)."
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete for: ${TARGET_LIST[*]}"
else
  echo "Uninstall complete for: ${TARGET_LIST[*]}"
fi
