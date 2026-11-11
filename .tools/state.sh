#!/usr/bin/env bash

# ============================================================
# Managed tool state
# ============================================================
#
# Purpose:
#   Record successful managed installations without executing state files.
#
# Notes:
#   TOOL_SHED_STATE_DIR overrides the per-user state directory for tests.
# ============================================================

tool_state_dir() {
  printf '%s\n' "${TOOL_SHED_STATE_DIR:-$HOME/.tool-shed/state}"
}

tool_state_valid_name() {
  [[ "$1" != *[!a-z0-9-]* && -n "$1" ]]
}

tool_state_has() {
  tool_state_valid_name "$1" && [[ -f "$(tool_state_dir)/tools/$1" ]]
}

tool_state_list() {
  local record
  for record in "$(tool_state_dir)"/tools/*; do
    [[ -f "$record" ]] || continue
    tool_state_valid_name "${record##*/}" || continue
    basename "$record"
  done
  return 0
}

tool_state_read() {
  tool_state_has "$1" || return 1
  IFS=$'\t' read -r STATE_MANAGER STATE_PACKAGE STATE_SOURCE STATE_PROFILE STATE_PATH STATE_VERSION < "$(tool_state_dir)/tools/$1"
  [[ -n "$STATE_MANAGER" && -n "$STATE_VERSION" ]]
}

tool_state_record() {
  [[ "${DRY_RUN:-false}" != true ]] || return 0
  local tool="$1" manager package source executable path version profile=none
  local selected_manager=direct selected_package=- selected_source=-
  tool_state_valid_name "$tool" || return 1
  catalog_tool_present "$tool" || return 1

  while IFS=$'\t' read -r manager package source; do
    [[ -n "$manager" ]] || continue
    if catalog_package_installed "$manager" "$package" "${source:-}"; then
      selected_manager="$manager"
      selected_package="$package"
      selected_source="${source:--}"
      break
    fi
  done < <(tool_package_specs "$tool")

  executable="$(tool_executable "$tool" 2>/dev/null || true)"
  path="$(command -v "${executable:-__missing_tool__}" || true)"
  if [[ "$selected_manager" == direct ]]; then
    case "$tool" in
      rust)
        if [[ "$path" == "${CARGO_HOME:-$HOME/.cargo}"/bin/* ]] && command -v rustup >/dev/null 2>&1; then
          selected_manager=rustup
        fi
        ;;
      julia)
        if [[ "$path" == "$HOME/.juliaup/bin/"* ]] && command -v juliaup >/dev/null 2>&1; then
          selected_manager=juliaup
        fi
        ;;
      nvm|node)
        catalog_source_nvm
        if command -v nvm >/dev/null 2>&1 && [[ "$tool" == nvm || "$path" == "${NVM_DIR:-$HOME/.nvm}"/versions/node/* ]]; then
          selected_manager=nvm
        fi
        ;;
    esac
  fi
  case "$tool" in
    python3) profile="${PYTHON_PACKAGE_PROFILE:-full}" ;;
    golang) profile="${GO_PACKAGE_PROFILE:-full}" ;;
    node) profile="${NODE_PACKAGE_PROFILE:-full}" ;;
  esac
  version="$(catalog_tool_installed_version "$tool")"
  if [[ "$selected_manager" != direct && "$selected_manager" != nvm && "$selected_manager" != rustup && "$selected_manager" != juliaup ]]; then
    version="$(catalog_package_version "$selected_manager" "$selected_package" "$([[ "$selected_source" == - ]] || printf '%s' "$selected_source")")" || return 1
  fi
  version="${version%%$'\n'*}"
  local value
  for value in "$selected_manager" "$selected_package" "$selected_source" "$profile" "${path:--}" "${version:-unknown}"; do
    [[ "$value" != *$'\t'* && "$value" != *$'\n'* ]] || return 1
  done

  local directory temporary
  directory="$(tool_state_dir)/tools"
  mkdir -p "$directory" || return 1
  temporary="$(mktemp "$directory/.record.XXXXXX")" || return 1
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$selected_manager" "$selected_package" "$selected_source" "$profile" "${path:--}" "${version:-unknown}" > "$temporary" || return 1
  mv -f "$temporary" "$directory/$tool"
}

tool_state_remove() {
  [[ "${DRY_RUN:-false}" != true ]] || return 0
  tool_state_valid_name "$1" || return 1
  rm -f "$(tool_state_dir)/tools/$1"
}

tool_state_record_bundle() {
  [[ "${DRY_RUN:-false}" != true ]] || return 0
  local bundle="$1" tool directory temporary
  case "$bundle" in full|cloud|services|ai) ;; *) return 0 ;; esac
  directory="$(tool_state_dir)/bundles"
  mkdir -p "$directory" || return 1
  temporary="$(mktemp "$directory/.bundle.XXXXXX")" || return 1
  while IFS= read -r tool; do
    if tool_state_has "$tool"; then
      printf '%s\n' "$tool" >> "$temporary"
    fi
  done < <(resolve_target_tools "$bundle")
  mv -f "$temporary" "$directory/$bundle"
}