#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tool update runtime
# ============================================================
#
# Purpose:
#   Apply managed updates without installing absent or unrelated tools.
#
# Notes:
#   Exit status 3 means a tool was safely skipped rather than updated.
# ============================================================

UPDATE_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UPDATE_TOOLS_DIR/tool-catalog.sh"
source "$UPDATE_TOOLS_DIR/state.sh"
UPDATE_PLATFORM_FILE="$TOOL_CATALOG_PLATFORM"
[[ "$UPDATE_PLATFORM_FILE" != mac ]] || UPDATE_PLATFORM_FILE=macos
source "$UPDATE_TOOLS_DIR/$UPDATE_PLATFORM_FILE.sh"

update_skip() {
  echo "SKIPPED: $*"
  return 3
}

module_update_entrypoint() {
  if [[ "${TOOL_SHED_UPDATE_INTERNAL:-false}" == true ]]; then
    module_update "$1"
  else
    exec bash "$UPDATE_TOOLS_DIR/update.sh" "$@"
  fi
}

update_run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

update_privileged() {
  if [[ "$(id -u)" == 0 ]]; then
    update_run "$@"
  elif command -v sudo >/dev/null 2>&1; then
    update_run sudo -n "$@"
  else
    echo "Root or non-interactive sudo is required for: $*" >&2
    return 1
  fi
}

update_major() {
  local version="${1#*:}"
  if [[ "$version" =~ ([0-9]+)\. ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

update_version_allowed() {
  [[ "${UPDATE_ALLOW_MAJOR:-false}" != true ]] || return 0
  local installed_major candidate_major
  installed_major="$(update_major "$1")" || return 1
  candidate_major="$(update_major "$2")" || return 1
  [[ "$installed_major" == "$candidate_major" ]]
}

update_checksum() {
  local file="$1" expected="$2" actual
  [[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || { echo "Missing valid SHA256 checksum for $file" >&2; return 1; }
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file")"
  else
    actual="$(shasum -a 256 "$file")"
  fi
  [[ "${actual%% *}" == "$expected" ]] || { echo "Checksum mismatch: $file" >&2; return 1; }
}

update_developer_packages() {
  [[ "${UPDATE_WITH_PACKAGES:-false}" == true ]] || return 0
  local tool="$1" package
  case "$tool" in
    python3)
      local python="$HOME/.local/share/tool-shed/python-venv/bin/python"
      [[ "$TOOL_CATALOG_PLATFORM" != windows ]] || python="$HOME/.local/share/tool-shed/python-venv/Scripts/python.exe"
      [[ -x "$python" ]] || { echo "Managed Python environment missing." >&2; return 1; }
      local packages=()
      while IFS= read -r package; do packages+=("$package"); done < <(get_tool_package_list python3 "$STATE_PROFILE")
      [[ ${#packages[@]} -gt 0 ]] || return 1
      update_run "$python" -m pip install --upgrade "${packages[@]}"
      ;;
    golang)
      local packages=()
      while IFS= read -r package; do packages+=("$package"); done < <(get_tool_package_list golang "$STATE_PROFILE")
      [[ ${#packages[@]} -gt 0 ]] || return 1
      for package in "${packages[@]}"; do update_run go install "$package" || return 1; done
      ;;
    node)
      local packages=()
      while IFS= read -r package; do packages+=("$package"); done < <(get_tool_package_list node "$STATE_PROFILE")
      [[ ${#packages[@]} -gt 0 ]] || return 1
      NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.local/share/tool-shed/node-global}" update_run npm install --global "${packages[@]}"
      ;;
  esac
}

update_prepare_packages() {
  local tool="$1" expected_manager="$2" manager package source installed latest held
  UPDATE_PACKAGES=()
  while IFS=$'\t' read -r manager package source; do
    [[ "$manager" == "$expected_manager" ]] || continue
    catalog_package_installed "$manager" "$package" "${source:-}" || continue
    case "$manager" in
      apt)
        held="$(apt-mark showhold)" || return 1
        if grep -Fxq "$package" <<< "$held"; then
          update_skip "$tool package $package is held."
          return 3
        fi
        ;;
      brew-formula)
        held="$(brew list --pinned)" || return 1
        if grep -Fxq "$package" <<< "$held"; then
          update_skip "$tool package $package is pinned."
          return 3
        fi
        ;;
    esac
    if [[ "${DRY_RUN:-false}" != true ]]; then
      installed="$(catalog_package_version "$manager" "$package" "${source:-}")" || return 1
      latest="$(catalog_package_latest "$manager" "$package" "${source:-}")" || return 1
      if [[ -z "$latest" || "$latest" == unknown || "$latest" == '(none)' ]]; then
        update_skip "$package has no known update candidate."
        return 3
      fi
      if ! update_version_allowed "$installed" "$latest"; then
        update_skip "$package ($installed -> $latest) requires --allow-major, or its version cannot be verified."
        return 3
      fi
    else
      echo "DRY RUN: $package candidate and major-version policy will be checked before updating."
    fi
    UPDATE_PACKAGES+=("$package")
  done < <(tool_package_specs "$tool")
  [[ ${#UPDATE_PACKAGES[@]} -gt 0 ]] || { update_skip "No installed packages for $tool."; return 3; }
}

module_update() {
  local tool executable current_path manager package source found=false
  tool="$(canonical_tool_name "$1")"
  case "$tool" in
    identity|git-config|git-signing|ssh-key|cloud)
      update_skip "$tool has no updatable installation; configuration and credentials are unchanged."
      return 3
      ;;
  esac
  tool_state_read "$tool" || { update_skip "$tool is not managed. Use .tools/update.sh --adopt $tool first."; return 3; }
  if [[ -f "$(tool_state_dir)/pins/$tool" ]]; then
    update_skip "$tool is pinned in the tool-shed state directory."
    return 3
  fi
  if [[ "$STATE_MANAGER" == nvm ]]; then
    catalog_source_nvm
  fi
  catalog_tool_present "$tool" || { update_skip "$tool is no longer installed."; return 3; }
  local service
  for service in "${SERVICES_BUNDLE[@]}" docker; do
    if [[ "$tool" == "$service" ]] && [[ "${UPDATE_INCLUDE_SERVICES:-false}" != true || "${UPDATE_YES:-false}" != true ]]; then
      update_skip "$tool requires --include-services --yes after taking a backup; updates may restart services."
      return 3
    fi
  done
  if [[ "$tool" == julia && "${UPDATE_ALLOW_MAJOR:-false}" != true ]]; then
    update_skip "Julia updates require --allow-major after reviewing the selected Juliaup channels."
    return 3
  fi
  executable="$(tool_executable "$tool" 2>/dev/null || true)"
  current_path="$(command -v "${executable:-__missing_tool__}" || true)"
  if [[ "$STATE_PATH" != - && "$current_path" != "$STATE_PATH" ]]; then
    update_skip "$tool executable changed ($STATE_PATH -> ${current_path:-missing}); review its installation source."
    return 3
  fi

  case "$STATE_MANAGER" in
    apt|brew-formula|brew-cask|winget|winget-store)
      while IFS=$'\t' read -r manager package source; do
        if [[ "$manager" == "$STATE_MANAGER" && "$package" == "$STATE_PACKAGE" && "${source:--}" == "$STATE_SOURCE" ]] && catalog_package_installed "$manager" "$package" "${source:-}"; then
          found=true
        fi
      done < <(tool_package_specs "$tool")
      if [[ "$found" != true ]]; then
        update_skip "$tool package source no longer matches its managed record."
        return 3
      fi
      if [[ "${TOOL_SHED_UPDATE_REFRESHED:-false}" != true && "${DRY_RUN:-false}" != true ]]; then
        catalog_refresh_latest_metadata || return 1
      fi
      "update_${TOOL_CATALOG_PLATFORM}" "$tool" || return $?
      if [[ "$tool" == rust ]] && command -v rustup >/dev/null 2>&1; then
        STATE_MANAGER=rustup update_native rust || return $?
      elif [[ "$tool" == julia ]] && command -v juliaup >/dev/null 2>&1; then
        STATE_MANAGER=juliaup update_native julia || return $?
      fi
      ;;
    direct|nvm|rustup|juliaup)
      update_native "$tool" || return $?
      ;;
    *) update_skip "Unknown update source for $tool: $STATE_MANAGER"; return 3 ;;
  esac
  update_developer_packages "$tool" || return 1
  if [[ "${DRY_RUN:-false}" != true ]]; then
    PYTHON_PACKAGE_PROFILE="$STATE_PROFILE" GO_PACKAGE_PROFILE="$STATE_PROFILE" NODE_PACKAGE_PROFILE="$STATE_PROFILE" tool_state_record "$tool" || return 1
  fi
}

update_native() {
  local tool="$1"
  case "$STATE_MANAGER:$tool" in
    rustup:rust)
      if [[ "${DRY_RUN:-false}" != true && "${UPDATE_ALLOW_MAJOR:-false}" != true ]]; then
        local check installed candidate
        check="$(rustup check)" || return 1
        while read -r installed candidate; do
          [[ -n "$installed" && -n "$candidate" ]] || continue
          update_version_allowed "$installed" "$candidate" || { update_skip "Rust toolchain change requires --allow-major."; return 3; }
        done < <(awk '{for (field=1; field<=NF; field++) if ($field == "->") print $(field-1), $(field+1)}' <<< "$check")
      fi
      update_run rustup update --no-self-update
      ;;
    juliaup:julia)
      if [[ "${UPDATE_ALLOW_MAJOR:-false}" != true ]]; then
        update_skip "Juliaup channels can cross major versions; review channels and pass --allow-major."
        return 3
      fi
      update_run juliaup update
      ;;
    nvm:node)
      catalog_source_nvm
      local version
      version="$(node --version)" || return 1
      local major
      major="$(update_major "$version")" || return 1
      local default_version
      default_version="$(nvm version default)" || return 1
      update_run nvm install "$major" --skip-default-packages || return 1
      if [[ "$default_version" == "$version" ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
          echo "DRY RUN: would advance the existing default alias within Node major $major."
        else
          nvm alias default "$(nvm current)" || return 1
        fi
      fi
      ;;
    *)
      if [[ "$TOOL_CATALOG_PLATFORM" == linux || "$tool" == nvm || "$tool" == scala ]]; then
        bash "$UPDATE_TOOLS_DIR/update-download.sh" "$tool"
      else
        update_skip "$tool uses a direct installation without a supported verified updater on this platform."
      fi
      ;;
  esac
}