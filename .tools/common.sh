#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tool bundle definitions
# ============================================================
#
# Purpose:
#   Maintain the canonical install bundles used by the repo's
#   developer bootstrap installer.
#
# Notes:
#   Keep bundle names stable and update the usage text in .tools/install.sh
#   whenever adding or changing install options.
# ============================================================

COMMON_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
REPO_ROOT="$(cd "$COMMON_TOOLS_DIR/.." && pwd)"

tool_shed_catalog_bundle_names() {
  tool_shed_catalog_bundle_key_entries | awk -F '\t' '{print $2}'
}

tool_shed_catalog_bundle_metadata_entries() {
  local catalog_path="$REPO_ROOT/.config/catalog.json"

  if [[ ! -f "$catalog_path" ]]; then
    echo "Missing required catalog file: $catalog_path" >&2
    return 1
  fi

  awk '
    BEGIN {
      in_bundles = 0
      bundles_depth = 0
      in_bundle = 0
      bundle_depth = 0
      bundle_name = ""
      bundle_key = ""
      friendly_name = ""
      description = ""
    }

    {
      if (!in_bundles && $0 ~ /"bundles"[[:space:]]*:[[:space:]]*\{/) {
        in_bundles = 1
        bundles_depth = 1
        next
      }

      if (in_bundles) {
        if (!in_bundle && match($0, /^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*\{[[:space:]]*$/)) {
          line = $0
          sub(/^[[:space:]]*"/, "", line)
          sub(/"[[:space:]]*:[[:space:]]*\{[[:space:]]*$/, "", line)
          bundle_name = line
          bundle_key = ""
          friendly_name = ""
          description = ""
          in_bundle = 1
          bundle_depth = 1
          bundles_depth += 1
          next
        }

        if (in_bundle) {
          if (bundle_depth == 1 && match($0, /^[[:space:]]*"key"[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]*,?[[:space:]]*$/)) {
            line = $0
            sub(/^[[:space:]]*"key"[[:space:]]*:[[:space:]]*/, "", line)
            sub(/[[:space:]]*,?[[:space:]]*$/, "", line)
            bundle_key = line
          } else if (bundle_depth == 1 && match($0, /^[[:space:]]*"friendlyName"[[:space:]]*:[[:space:]]*"[^"]+"[[:space:]]*,?[[:space:]]*$/)) {
            line = $0
            sub(/^[[:space:]]*"friendlyName"[[:space:]]*:[[:space:]]*"/, "", line)
            sub(/"[[:space:]]*,?[[:space:]]*$/, "", line)
            friendly_name = line
          } else if (bundle_depth == 1 && match($0, /^[[:space:]]*"description"[[:space:]]*:[[:space:]]*"[^"]+"[[:space:]]*,?[[:space:]]*$/)) {
            line = $0
            sub(/^[[:space:]]*"description"[[:space:]]*:[[:space:]]*"/, "", line)
            sub(/"[[:space:]]*,?[[:space:]]*$/, "", line)
            description = line
          }

          line = $0
          opens = gsub(/\{/, "{", line)
          closes = gsub(/\}/, "}", line)
          bundle_depth += opens - closes
          if (bundle_depth <= 0) {
            if (friendly_name == "") {
              friendly_name = bundle_name
            }
            printf "%s\t%s\t%s\t%s\n", bundle_key, bundle_name, friendly_name, description
            in_bundle = 0
            bundle_name = ""
          }
        }

        line = $0
        opens = gsub(/\{/, "{", line)
        closes = gsub(/\}/, "}", line)
        bundles_depth += opens - closes
        if (bundles_depth <= 0) {
          in_bundles = 0
        }
      }
    }
  ' "$catalog_path" | sort -n -k1,1
}

tool_shed_catalog_bundle_key_entries() {
  tool_shed_catalog_bundle_metadata_entries | awk -F '\t' '{print $1"\t"$2}'
}

tool_shed_catalog_bundle_name_for_key() {
  local bundle_key="$1"
  local key
  local bundle_name

  while IFS=$'\t' read -r key bundle_name; do
    if [[ "$key" == "$bundle_key" ]]; then
      printf '%s\n' "$bundle_name"
      return 0
    fi
  done < <(tool_shed_catalog_bundle_key_entries)

  return 1
}

tool_shed_catalog_has_bundle_name() {
  local candidate="$1"
  local bundle_name

  while IFS= read -r bundle_name; do
    if [[ "$bundle_name" == "$candidate" ]]; then
      return 0
    fi
  done < <(tool_shed_catalog_bundle_names)

  return 1
}

tool_shed_print_numbered_bundles() {
  local key
  local bundle_name
  local friendly_name
  local description

  while IFS=$'\t' read -r key bundle_name friendly_name description; do
    if [[ -n "$description" ]]; then
      printf '  %s) %s (%s): %s\n' "$key" "$friendly_name" "$bundle_name" "$description"
    else
      printf '  %s) %s (%s)\n' "$key" "$friendly_name" "$bundle_name"
    fi
  done < <(tool_shed_catalog_bundle_metadata_entries)
}

tool_shed_supported_bundles_csv() {
  local bundles=()
  local out=""
  local item

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    bundles+=("$item")
  done < <(tool_shed_catalog_bundle_names)

  for item in "${bundles[@]}"; do
    if [[ -z "$out" ]]; then
      out="$item"
    else
      out+=", $item"
    fi
  done

  printf '%s\n' "$out"
}

tool_shed_supported_bundles_pattern() {
  local bundles=()
  local out=""
  local item

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    bundles+=("$item")
  done < <(tool_shed_catalog_bundle_names)

  for item in "${bundles[@]}"; do
    if [[ -z "$out" ]]; then
      out="$item"
    else
      out+="|$item"
    fi
  done

  printf '%s\n' "$out"
}

tool_shed_catalog_bundle_entries() {
  local bundle_name="$1"
  local catalog_path="$REPO_ROOT/.config/catalog.json"

  awk -v bundle="$bundle_name" '
    BEGIN {
      in_bundles = 0
      bundles_depth = 0
      in_target = 0
      target_depth = 0
      in_tools = 0
      tools_depth = 0
      current_tool = ""
    }

    /"bundles"[[:space:]]*:[[:space:]]*\{/ {
      in_bundles = 1
      bundles_depth = 1
      next
    }

    in_bundles {
      if (!in_target && match($0, "^[[:space:]]*\"" bundle "\"[[:space:]]*:[[:space:]]*\\{")) {
        in_target = 1
        target_depth = 1
        next
      }

      if (in_target) {
        if (!in_tools && match($0, /^[[:space:]]*"tools"[[:space:]]*:[[:space:]]*\{[[:space:]]*$/)) {
          in_tools = 1
          tools_depth = 1
        } else if (in_tools) {
          if (match($0, /^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*\{[[:space:]]*$/)) {
            line = $0
            sub(/^[[:space:]]*"/, "", line)
            sub(/"[[:space:]]*:[[:space:]]*\{[[:space:]]*$/, "", line)
            if (line != "order") {
              current_tool = line
            }
          } else if (current_tool != "" && match($0, /^[[:space:]]*"key"[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]*,?[[:space:]]*$/)) {
            line = $0
            sub(/^[[:space:]]*"key"[[:space:]]*:[[:space:]]*/, "", line)
            sub(/[[:space:]]*,?[[:space:]]*$/, "", line)
            printf "%s\t%s\n", line, current_tool
            current_tool = ""
          }

          line = $0
          opens = gsub(/\{/, "{", line)
          closes = gsub(/\}/, "}", line)
          tools_depth += opens - closes
          if (tools_depth <= 0) {
            in_tools = 0
          }
        }

        line = $0
        opens = gsub(/\{/, "{", line)
        closes = gsub(/\}/, "}", line)
        target_depth += opens - closes
        if (target_depth <= 0) {
          in_target = 0
        }
      }

      line = $0
      opens = gsub(/\{/, "{", line)
      closes = gsub(/\}/, "}", line)
      bundles_depth += opens - closes
      if (bundles_depth <= 0) {
        in_bundles = 0
      }
    }
  ' "$catalog_path" | sort -n -k1,1
}

tool_shed_catalog_has_tool_key() {
  local tool_key="$1"
  local catalog_path="$REPO_ROOT/.config/catalog.json"

  awk -v key="$tool_key" '
    /"tools"[[:space:]]*:[[:space:]]*\{/ {
      in_tools = 1
      depth = 1
      next
    }
    in_tools {
      if (match($0, /^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*\{/)) {
        split($0, parts, "\"")
        if (length(parts) >= 3 && parts[2] == key) {
          found = 1
        }
      }

      line = $0
      opens = gsub(/\{/, "{", line)
      closes = gsub(/\}/, "}", line)
      depth += opens - closes

      if (depth <= 0) {
        in_tools = 0
      }
    }
    END {
      if (found == 1) {
        exit 0
      }
      exit 1
    }
  ' "$catalog_path"
}

tool_shed_load_bundle_array() {
  local bundle_name="$1"
  local target_array="$2"
  local order
  local value
  local escaped
  local items=()
  local parsed=()
  local expected_order=0

  while IFS=$'\t' read -r order value; do
    parsed+=("$order"$'\t'"$value")
  done < <(tool_shed_catalog_bundle_entries "$bundle_name")

  if [[ ${#parsed[@]} -eq 0 ]]; then
    echo "No bundle entries parsed from .config/catalog.json for bundle: $bundle_name" >&2
    return 1
  fi

  for entry in "${parsed[@]}"; do
    order="${entry%%$'\t'*}"
    value="${entry#*$'\t'}"

    if [[ -z "$order" || -z "$value" ]]; then
      echo "Invalid bundle entry in .config/catalog.json for bundle: $bundle_name" >&2
      return 1
    fi

    if [[ "$order" != "$expected_order" ]]; then
      echo "Bundle $bundle_name keys must be contiguous from 0; expected $expected_order got $order" >&2
      return 1
    fi
    expected_order=$((expected_order + 1))

    items+=("$value")
  done

  eval "$target_array=()"
  for value in "${items[@]}"; do
    if ! tool_shed_catalog_has_tool_key "$value"; then
      echo "Bundle $bundle_name references unknown tool key in .config/catalog.json: $value" >&2
      return 1
    fi
    escaped="$(printf '%q' "$value")"
    eval "$target_array+=($escaped)"
  done
}

tool_shed_load_bundles_from_catalog() {
  tool_shed_load_bundle_array "full" FULL_BUNDLE
  tool_shed_load_bundle_array "cloud" CLOUD_BUNDLE
  tool_shed_load_bundle_array "services" SERVICES_BUNDLE
  tool_shed_load_bundle_array "ai" AI_BUNDLE
  tool_shed_load_bundle_array "software-developer" SOFTWARE_DEVELOPER_BUNDLE
  tool_shed_load_bundle_array "data-science" DATA_SCIENCE_BUNDLE
}

tool_shed_load_bundles_from_catalog

UPDATEABLE_TOOLS=(
  git
  gpg
  curl
  wget
  unzip
  python3
  r
  nvm
  node
  golang
  cpp
  rust
  java
  scala
  julia
  kubectl
  helm
  docker
  dotnetcore
  vscode
  gcloud
  aws
  eksctl
  az
  doctl
  jq
  yq
  postgres
  redis
  mysql
  clickhouse
  mongodb
  rabbitmq
  elasticsearch
  kafka
  direnv
  kind
  stern
  kubeseal
  httpie
  rg
  fd
  bat
  eza
  fzf
  gh
  terraform
  tflint
  k9s
  trivy
)

ALL_TOOLS=("${UPDATEABLE_TOOLS[@]}" git-config git-signing identity ssh-key)

TOOL_SHED_VERBOSE="${TOOL_SHED_VERBOSE:-0}"
TOOL_SHED_PROGRESS="${TOOL_SHED_PROGRESS:-auto}"
TOOL_SHED_PROGRESS_ENABLED=false
TOOL_SHED_PROGRESS_TEXT=false
TOOL_SHED_PROGRESS_LABEL=""
TOOL_SHED_PROGRESS_TOTAL=0
TOOL_SHED_PROGRESS_DONE=0
TOOL_SHED_PROGRESS_TOOL=""
TOOL_SHED_PROGRESS_TOOL_BASE=""
TOOL_SHED_PROGRESS_TOOL_TOTAL=0
TOOL_SHED_PROGRESS_TOOL_DONE=0

tool_shed_set_verbose() {
  local enabled="${1:-false}"
  if [[ "$enabled" == true ]]; then
    TOOL_SHED_VERBOSE=1
  else
    TOOL_SHED_VERBOSE=0
  fi
  export TOOL_SHED_VERBOSE
}

tool_shed_verbose_enabled() {
  [[ "${TOOL_SHED_VERBOSE:-0}" == "1" ]]
}

tool_shed_print_verbose() {
  tool_shed_verbose_enabled || return 0
  printf '%s\n' "$*"
}

# Keep module output concise unless verbose mode is enabled.
tool_shed_run_with_output_mode() {
  if tool_shed_verbose_enabled; then
    "$@"
    return $?
  fi

  local captured
  local status=0
  captured="$(mktemp)"
  "$@" >"$captured" 2>&1 || status=$?
  if [[ "$status" != 0 ]]; then
    cat "$captured"
  fi
  rm -f "$captured"
  return "$status"
}

tool_shed_progress_bar() {
  local done="$1"
  local total="$2"
  local width=24
  local filled=0
  local percent=0

  if (( total > 0 )); then
    percent=$((done * 100 / total))
    filled=$((done * width / total))
  fi
  (( percent > 100 )) && percent=100
  (( filled > width )) && filled=width

  local bar=""
  local index
  for ((index = 0; index < filled; index++)); do
    bar+="#"
  done
  for ((index = filled; index < width; index++)); do
    bar+="-"
  done

  printf '[%s] %3d%% (%d/%d)' "$bar" "$percent" "$done" "$total"
}

tool_shed_progress_render() {
  [[ "$TOOL_SHED_PROGRESS_ENABLED" == true || "$TOOL_SHED_PROGRESS_TEXT" == true ]] || return 0

  local overall_line
  local tool_line
  overall_line="Overall  $(tool_shed_progress_bar "$TOOL_SHED_PROGRESS_DONE" "$TOOL_SHED_PROGRESS_TOTAL") ${TOOL_SHED_PROGRESS_LABEL}"
  tool_line="Current  ${TOOL_SHED_PROGRESS_TOOL:-idle} $(tool_shed_progress_bar "$TOOL_SHED_PROGRESS_TOOL_DONE" "$TOOL_SHED_PROGRESS_TOOL_TOTAL")"

  printf '%s\n' "$overall_line"
  printf '%s\n' "$tool_line"
}

tool_shed_progress_init() {
  local label="$1"
  local total="${2:-0}"
  local mode="${TOOL_SHED_PROGRESS:-auto}"

  TOOL_SHED_PROGRESS_LABEL="$label"
  TOOL_SHED_PROGRESS_TOTAL="$total"
  TOOL_SHED_PROGRESS_DONE=0
  TOOL_SHED_PROGRESS_TOOL="idle"
  TOOL_SHED_PROGRESS_TOOL_TOTAL=1
  TOOL_SHED_PROGRESS_TOOL_DONE=0

  TOOL_SHED_PROGRESS_ENABLED=false
  TOOL_SHED_PROGRESS_TEXT=false
  if [[ "$mode" == on ]]; then
    TOOL_SHED_PROGRESS_ENABLED=true
  elif [[ "$mode" == off ]]; then
    TOOL_SHED_PROGRESS_ENABLED=false
    TOOL_SHED_PROGRESS_TEXT=false
  elif [[ -t 1 ]]; then
    TOOL_SHED_PROGRESS_ENABLED=true
  else
    TOOL_SHED_PROGRESS_TEXT=true
  fi

  tool_shed_progress_render
}

tool_shed_progress_start_tool() {
  TOOL_SHED_PROGRESS_TOOL_BASE="$1"
  TOOL_SHED_PROGRESS_TOOL="$1"
  TOOL_SHED_PROGRESS_TOOL_TOTAL="${2:-1}"
  TOOL_SHED_PROGRESS_TOOL_DONE=0
  tool_shed_progress_render
}

tool_shed_progress_tick_tool() {
  local phase="${1:-}"
  if [[ -n "$phase" && -n "$TOOL_SHED_PROGRESS_TOOL_BASE" ]]; then
    TOOL_SHED_PROGRESS_TOOL="$TOOL_SHED_PROGRESS_TOOL_BASE:$phase"
  fi
  if (( TOOL_SHED_PROGRESS_TOOL_DONE < TOOL_SHED_PROGRESS_TOOL_TOTAL )); then
    TOOL_SHED_PROGRESS_TOOL_DONE=$((TOOL_SHED_PROGRESS_TOOL_DONE + 1))
  fi
  tool_shed_progress_render
}

tool_shed_progress_finish_tool() {
  TOOL_SHED_PROGRESS_TOOL_DONE="$TOOL_SHED_PROGRESS_TOOL_TOTAL"
  if (( TOOL_SHED_PROGRESS_DONE < TOOL_SHED_PROGRESS_TOTAL )); then
    TOOL_SHED_PROGRESS_DONE=$((TOOL_SHED_PROGRESS_DONE + 1))
  fi
  tool_shed_progress_render
}

tool_shed_progress_finish() {
  TOOL_SHED_PROGRESS_TOOL="complete"
  TOOL_SHED_PROGRESS_TOOL_TOTAL=1
  TOOL_SHED_PROGRESS_TOOL_DONE=1
  TOOL_SHED_PROGRESS_DONE="$TOOL_SHED_PROGRESS_TOTAL"
  tool_shed_progress_render
}

get_tool_package_list() {
  local tool_name="${1:-}"
  local profile="${2:-full}"
  local package_list=()

  case "$tool_name" in
    python3)
      if [[ -f "$REPO_ROOT/python3/packages.sh" ]]; then
        source "$REPO_ROOT/python3/packages.sh"
      fi
      if [[ "$profile" == "core" ]]; then
        package_list=("${PYTHON_CORE_PACKAGES[@]}")
      elif [[ "$profile" == "ai" ]]; then
        package_list=("${PYTHON_AI_PACKAGES[@]}")
      else
        package_list=("${PYTHON_FULL_PACKAGES[@]}")
      fi
      ;;
    golang)
      if [[ -f "$REPO_ROOT/golang/packages.sh" ]]; then
        source "$REPO_ROOT/golang/packages.sh"
      fi
      if [[ "$profile" == "core" ]]; then
        package_list=("${GO_CORE_PACKAGES[@]}")
      elif [[ "$profile" == "ai" ]]; then
        package_list=("${GO_AI_PACKAGES[@]}")
      else
        package_list=("${GO_FULL_PACKAGES[@]}")
      fi
      ;;
    node)
      if [[ -f "$REPO_ROOT/node/packages.sh" ]]; then
        source "$REPO_ROOT/node/packages.sh"
      fi
      if [[ "$profile" == "core" ]]; then
        package_list=("${NODE_CORE_PACKAGES[@]}")
      else
        package_list=("${NODE_FULL_PACKAGES[@]}")
      fi
      ;;
    *)
      return 1
      ;;
  esac

  if [[ ${#package_list[@]} -eq 0 ]]; then
    return 1
  fi

  printf '%s\n' "${package_list[@]}"
}

ensure_rustup_default() {
  local toolchains
  toolchains="$(rustup toolchain list)"
  if ! grep -q ' (default)$' <<< "$toolchains"; then
    rustup default stable
  fi
}

install_rustup_if_missing() {
  export PATH="$HOME/.cargo/bin:$PATH"

  if command -v rustup >/dev/null 2>&1; then
    ensure_rustup_default
    echo "rustup is already installed; preserving its existing default toolchain."
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install rustup." >&2
    return 1
  fi

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
  export PATH="$HOME/.cargo/bin:$PATH"
  ensure_rustup_default
}

install_scala_cli_if_missing() {
  if command -v scala-cli >/dev/null 2>&1; then
    echo "Scala CLI is already installed."
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install Scala CLI." >&2
    return 1
  fi

  curl -fsSL https://scala-cli.virtuslab.org/get | sh
}

install_juliaup_if_missing() {
  export PATH="$HOME/.juliaup/bin:$PATH"

  if command -v juliaup >/dev/null 2>&1; then
    echo "Juliaup is already installed; preserving its existing channels and default."
    return 0
  fi

  if command -v julia >/dev/null 2>&1; then
    echo "Julia is already installed without Juliaup; leaving the existing installation unchanged."
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install Juliaup." >&2
    return 1
  fi

  curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel release
  export PATH="$HOME/.juliaup/bin:$PATH"
}

install_python_dev_packages() {
  local python_cmd="${1:-python3}"
  local package_profile="${PYTHON_PACKAGE_PROFILE:-full}"
  local package_list=()

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && package_list+=("$pkg")
  done < <(get_tool_package_list "python3" "$package_profile") || {
    echo "Python package manifest not found."
    return 0
  }

  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    echo "Python executable not found: $python_cmd"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "DRY RUN: would install Python developer packages with $python_cmd ($package_profile profile)"
    printf '  - %s\n' "${package_list[@]}"
    return 0
  fi

  local venv_dir="$HOME/.local/share/tool-shed/python-venv"
  local venv_python="$venv_dir/bin/python"
  local venv_bin="$venv_dir/bin"
  local shell_profile="$HOME/.bashrc"
  case "${TOOL_SHED_OS_OVERRIDE:-$(uname -s)}" in
    MINGW*|MSYS*|CYGWIN*|Windows_NT)
      venv_python="$venv_dir/Scripts/python.exe"
      venv_bin="$venv_dir/Scripts"
      ;;
  esac

  echo "Installing Python developer packages in $venv_dir ($package_profile profile)..."
  if [[ ! -x "$venv_python" ]]; then
    "$python_cmd" -m venv "$venv_dir"
  fi
  "$venv_python" -m pip install --upgrade pip setuptools wheel
  "$venv_python" -m pip install "${package_list[@]}"

  if ! grep -Fq "$venv_bin" "$shell_profile" 2>/dev/null; then
    printf '\n# Tool-shed Python developer tools\nexport PATH="%s:$PATH"\n' "$venv_bin" >> "$shell_profile"
  fi
}

install_go_dev_packages() {
  local go_cmd="${1:-go}"
  local package_profile="${GO_PACKAGE_PROFILE:-full}"
  local package_list=()

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && package_list+=("$pkg")
  done < <(get_tool_package_list "golang" "$package_profile") || {
    echo "Go package manifest not found."
    return 0
  }

  if ! command -v "$go_cmd" >/dev/null 2>&1; then
    echo "Go executable not found: $go_cmd"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "DRY RUN: would install Go developer packages with $go_cmd ($package_profile profile)"
    printf '  - %s\n' "${package_list[@]}"
    return 0
  fi

  echo "Installing Go developer packages via go install ($package_profile profile)..."
  export PATH="$PATH:$HOME/go/bin"
  for pkg in "${package_list[@]}"; do
    "$go_cmd" install "$pkg"
  done
}

install_node_dev_packages() {
  local node_cmd="${1:-node}"
  local package_profile="${NODE_PACKAGE_PROFILE:-full}"
  local package_list=()

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && package_list+=("$pkg")
  done < <(get_tool_package_list "node" "$package_profile") || {
    echo "Node package manifest not found."
    return 0
  }

  if ! command -v "$node_cmd" >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Node or npm executable not found."
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "DRY RUN: would install Node developer packages with npm ($package_profile profile)"
    printf '  - %s\n' "${package_list[@]}"
    return 0
  fi

  echo "Installing Node developer packages via npm ($package_profile profile)..."
  local npm_prefix="${NPM_CONFIG_PREFIX:-$HOME/.local/share/tool-shed/node-global}"
  mkdir -p "$npm_prefix"
  export NPM_CONFIG_PREFIX="$npm_prefix"
  export PATH="$npm_prefix/bin:$PATH"
  npm install --global "${package_list[@]}"
}

configure_git_editor() {
  if ! command -v git >/dev/null 2>&1 || ! command -v vim >/dev/null 2>&1; then
    return 0
  fi

  local current_editor
  current_editor="$(git config --global --get core.editor || true)"
  if [[ -z "$current_editor" ]]; then
    git config --global core.editor vim
    echo "Git default editor set to vim."
  elif [[ "$current_editor" != "vim" ]]; then
    echo "Git core.editor already set to '$current_editor'; leaving it unchanged."
  fi
}

configure_git_identity() {
  local name="${GIT_USER_NAME:-}"
  local email="${GIT_USER_EMAIL:-}"

  if [[ -z "$name" || -z "$email" ]]; then
    echo "Git identity not configured."
    echo "Set GIT_USER_NAME and GIT_USER_EMAIL before running git-config."
    return 1
  fi

  git config --global user.name "$name"
  git config --global user.email "$email"

  echo "Git identity configured:"
  git config --global --get user.name
  git config --global --get user.email
}

configure_git_signing() {
  if ! command -v gpg >/dev/null 2>&1; then
    echo "GPG is not installed yet. Install gpg first or include it in the install command."
    return 1
  fi

  git config --global commit.gpgsign true
  git config --global tag.gpgSign true
  git config --global gpg.program "$(command -v gpg)"

  local signing_key="${GPG_KEY_ID:-}"
  if [[ -z "$signing_key" ]]; then
    signing_key="$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | awk '/sec/{print $2; exit}' | cut -d/ -f2 || true)"
  fi

  if [[ -n "$signing_key" ]]; then
    git config --global user.signingkey "$signing_key"
  fi

  echo "Git commit signing enabled."
  git config --global --get user.signingkey || true
}

configure_gpg_key() {
  local name="${GIT_USER_NAME:-}"
  local email="${GIT_USER_EMAIL:-}"

  if [[ -z "$name" || -z "$email" ]]; then
    echo "Git identity not configured. Set GIT_USER_NAME and GIT_USER_EMAIL before creating a GPG key."
    return 1
  fi

  if ! command -v gpg >/dev/null 2>&1; then
    echo "GPG is not installed yet. Install it with: bash ./.tools/install.sh gpg"
    return 1
  fi

  if gpg --list-secret-keys --with-colons "$email" 2>/dev/null | grep -q '^sec:'; then
    echo "A GPG signing key already exists for $email"
    local existing_key
    existing_key="$(gpg --list-secret-keys --keyid-format LONG "$email" 2>/dev/null | awk '/sec/{print $2; exit}' | cut -d/ -f2 || true)"
    if [[ -n "$existing_key" ]]; then
      export GPG_KEY_ID="$existing_key"
      git config --global user.signingkey "$existing_key"
    fi
    return 0
  fi

  GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
  mkdir -p "$GNUPGHOME"
  chmod 700 "$GNUPGHOME"

  echo "Generating a new GPG signing key for $name <$email>..."
  gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key "$name <$email>" ed25519 sign 1y

  local generated_key
  generated_key="$(gpg --list-secret-keys --keyid-format LONG "$email" 2>/dev/null | awk '/sec/{print $2; exit}' | cut -d/ -f2 || true)"

  if [[ -n "$generated_key" ]]; then
    export GPG_KEY_ID="$generated_key"
    git config --global user.signingkey "$generated_key"
    echo "Generated GPG key: $generated_key"
    return 0
  fi

  echo "Unable to determine the generated GPG key ID."
  return 1
}

configure_ssh_key() {
  local key_path="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
  local email="${SSH_KEY_EMAIL:-${GIT_USER_EMAIL:-}}"
  local comment="${SSH_KEY_COMMENT:-${GIT_USER_NAME:-${USER:-$(whoami)}}@$(hostname)}"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [[ -f "$key_path" ]]; then
    echo "SSH key already exists at $key_path"
    return 0
  fi

  if [[ -z "$email" ]]; then
    echo "SSH key not configured. Set SSH_KEY_EMAIL or GIT_USER_EMAIL before running ssh-key."
    return 1
  fi

  ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N "" -q

  if command -v ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
  fi

  if command -v ssh-add >/dev/null 2>&1; then
    ssh-add "$key_path" >/dev/null 2>&1 || true
  fi

  echo "SSH key created at $key_path"
  echo "Public key:"
  cat "$key_path.pub"
}

configure_git_completion() {
  # Enable git tab completion in bash
  local shell_profile="$HOME/.bashrc"
  local completion_source=""

  # Determine which completion file to source based on platform
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS: git-completion comes with bash-completion via Homebrew
    if [[ -f /usr/local/etc/bash_completion.d/git-completion.bash ]]; then
      completion_source="/usr/local/etc/bash_completion.d/git-completion.bash"
    elif [[ -f /opt/homebrew/etc/bash_completion.d/git-completion.bash ]]; then
      completion_source="/opt/homebrew/etc/bash_completion.d/git-completion.bash"
    fi
  else
    # Linux: git-completion is in /usr/share/bash-completion/completions/
    if [[ -f /usr/share/bash-completion/completions/git ]]; then
      completion_source="/usr/share/bash-completion/completions/git"
    fi
  fi

  if [[ -z "$completion_source" ]]; then
    return 0
  fi

  # Add source line to bashrc if not already present
  if ! grep -q "source.*git.*completion" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# Git completion" >> "$shell_profile"
    echo "[[ -f $completion_source ]] && source $completion_source" >> "$shell_profile"
  fi
}

configure_kubectl_completion() {
  # Enable kubectl tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v kubectl >/dev/null 2>&1; then
    return 0
  fi
  
  if ! grep -q "kubectl completion bash" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# kubectl completion" >> "$shell_profile"
    echo "source <(kubectl completion bash)" >> "$shell_profile"
  fi
}

configure_helm_completion() {
  # Enable helm tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v helm >/dev/null 2>&1; then
    return 0
  fi
  
  if ! grep -q "helm completion bash" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# helm completion" >> "$shell_profile"
    echo "source <(helm completion bash)" >> "$shell_profile"
  fi
}

configure_docker_completion() {
  # Enable docker tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v docker >/dev/null 2>&1; then
    return 0
  fi
  
  if ! grep -q "docker completion" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# docker completion" >> "$shell_profile"
    echo "source <(docker completion bash 2>/dev/null)" >> "$shell_profile"
  fi
}

configure_aws_completion() {
  # Enable aws tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v aws >/dev/null 2>&1; then
    return 0
  fi
  
  if ! grep -q "aws_completer" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# aws completion" >> "$shell_profile"
    echo "complete -C '$(which aws_completer)' aws" >> "$shell_profile"
  fi
}

configure_gcloud_completion() {
  # Enable gcloud tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v gcloud >/dev/null 2>&1; then
    return 0
  fi
  
  # gcloud completion is typically installed with gcloud itself
  local completion_source=""
  if [[ -f "$HOME/.local/share/google-cloud-sdk/completion.bash.inc" ]]; then
    completion_source="$HOME/.local/share/google-cloud-sdk/completion.bash.inc"
  elif [[ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc ]]; then
    completion_source="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
  elif [[ -f /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc ]]; then
    completion_source="/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
  fi
  
  if [[ -z "$completion_source" ]]; then
    return 0
  fi
  
  if ! grep -q "gcloud.*completion" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# gcloud completion" >> "$shell_profile"
    echo "[[ -f $completion_source ]] && source $completion_source" >> "$shell_profile"
  fi
}

configure_az_completion() {
  # Enable azure-cli tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v az >/dev/null 2>&1; then
    return 0
  fi
  
  if ! grep -q "az_completer" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# az completion" >> "$shell_profile"
    echo "source <(az completion bash 2>/dev/null)" >> "$shell_profile"
  fi
}

configure_doctl_completion() {
  # Enable doctl tab completion in bash
  local shell_profile="$HOME/.bashrc"
  
  if ! command -v doctl >/dev/null 2>&1; then
    return 0
  fi
  
  if ! grep -q "doctl completion bash" "$shell_profile" 2>/dev/null; then
    echo "" >> "$shell_profile"
    echo "# doctl completion" >> "$shell_profile"
    echo "source <(doctl completion bash)" >> "$shell_profile"
  fi
}

configure_identity_interactive() {
  local name="${GIT_USER_NAME:-}"
  local email="${GIT_USER_EMAIL:-}"
  local ssh_email="${SSH_KEY_EMAIL:-}"
  local answer=""

  if [[ -z "$name" ]]; then
    read -r -p 'Git user name: ' name
  fi

  if [[ -z "$email" ]]; then
    read -r -p 'Git user email: ' email
  fi

  if [[ -n "$name" && -n "$email" ]]; then
    export GIT_USER_NAME="$name"
    export GIT_USER_EMAIL="$email"
    configure_git_identity || true
  fi

  if ! command -v gpg >/dev/null 2>&1; then
    if [[ -n "${1:-}" ]]; then
      echo "GPG not installed. Run: $0 gpg"
    fi
  else
    read -r -p "Generate a new GPG signing key for ${email:-$name}? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      configure_gpg_key || true
      configure_git_signing || true
    else
      configure_git_signing || true
    fi
  fi

  if [[ -z "$ssh_email" ]]; then
    read -r -p "SSH key email [default: ${email:-your-email@example.com}]: " ssh_email
  fi

  if [[ -z "$ssh_email" ]]; then
    ssh_email="${email:-}"
  fi

  if [[ -n "$ssh_email" ]]; then
    export SSH_KEY_EMAIL="$ssh_email"
    configure_ssh_key || true
  fi
}

ensure_root_or_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
  elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    SUDO=""
  fi
}

install_pkg() {
  local pkg="$1"
  if command -v "$pkg" >/dev/null 2>&1; then
    echo "$pkg already installed"
    return
  fi

  if [[ -n "${SUDO:-}" ]]; then
    $SUDO apt-get install -y "$pkg"
  else
    apt-get install -y "$pkg"
  fi
}

canonical_tool_name() {
  local tool="$1"

  case "$tool" in
    juliaup)
      echo "julia"
      ;;
    R|r-lang)
      echo "r"
      ;;
    scala-cli)
      echo "scala"
      ;;
    rustup)
      echo "rust"
      ;;
    c++)
      echo "cpp"
      ;;
    jdk)
      echo "java"
      ;;
    kubernetes-cli)
      echo "kubectl"
      ;;
    google-cloud)
      echo "gcloud"
      ;;
    awscli)
      echo "aws"
      ;;
    azure|azure-cli)
      echo "az"
      ;;
    digitalocean|doks)
      echo "doctl"
      ;;
    dotnet)
      echo "dotnetcore"
      ;;
    code)
      echo "vscode"
      ;;
    python-core)
      echo "python3"
      ;;
    python-full)
      echo "python3"
      ;;
    python-ai)
      echo "python3"
      ;;
    python)
      echo "python3"
      ;;
    go-core)
      echo "golang"
      ;;
    go-full)
      echo "golang"
      ;;
    go-ai)
      echo "golang"
      ;;
    go|golang)
      echo "golang"
      ;;
    java|jdk|openjdk|temurin)
      echo "java"
      ;;
    node-core)
      echo "node"
      ;;
    node-full|node)
      echo "node"
      ;;
    *)
      echo "$tool"
      ;;
  esac
}

expand_bundle_item() {
  local item="$1"
  local bundle_from_key=""
  local key
  local value

  if [[ "$item" =~ ^[0-9]+$ ]]; then
    bundle_from_key="$(tool_shed_catalog_bundle_name_for_key "$item" || true)"
    if [[ -n "$bundle_from_key" ]]; then
      item="$bundle_from_key"
    fi
  fi

  if tool_shed_catalog_has_bundle_name "$item"; then
    while IFS=$'\t' read -r key value; do
      [[ -z "$value" ]] && continue
      printf '%s\n' "$value"
    done < <(tool_shed_catalog_bundle_entries "$item")
    return 0
  fi

  case "$item" in
    python-core)
      printf '%s\n' "python3"
      ;;
    python-full)
      printf '%s\n' "python3"
      ;;
    python-ai)
      printf '%s\n' "python3"
      ;;
    python)
      printf '%s\n' "python3"
      ;;
    go-core)
      printf '%s\n' "golang"
      ;;
    go-full)
      printf '%s\n' "golang"
      ;;
    go-ai)
      printf '%s\n' "golang"
      ;;
    go)
      printf '%s\n' "golang"
      ;;
    node-core)
      printf '%s\n' "node"
      ;;
    node-full)
      printf '%s\n' "node"
      ;;
    node)
      printf '%s\n' "node"
      ;;
    *)
      printf '%s\n' "$item"
      ;;
  esac
}

resolve_target_tools() {
  local expanded=()
  local item
  for item in "$@"; do
    while IFS= read -r expanded_item; do
      [[ -z "$expanded_item" ]] && continue
      expanded+=("$(canonical_tool_name "$expanded_item")")
    done < <(expand_bundle_item "$item")
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
