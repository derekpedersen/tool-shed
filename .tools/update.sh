#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Managed tool updater
# ============================================================
#
# Purpose:
#   Update installed tools and bundles through their recorded sources.
#
# Notes:
#   No targets means all managed tools, never all tools on the machine.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/update-runtime.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: bash .tools/update.sh [full|cloud|services|ai|all|TOOL ...] [options]"
  echo "No targets: update all managed, installed tools. Missing tools are never installed."
  echo "  --dry-run, -n       Preview without downloads, metadata refreshes, or writes"
  echo "  --adopt             Record existing selected installations, without updating"
  echo "  --list              Show recorded tools and requested bundles"
  echo "  --allow-major       Allow package major-version changes (pins still apply)"
  echo "  --include-services  Include database/service tools (requires --yes)"
  echo "  --yes               Confirm service-update restart and migration risks"
  echo "  --with-packages     Also update recorded Python/Go/Node developer profiles"
}

export DRY_RUN=false UPDATE_ALLOW_MAJOR=false UPDATE_INCLUDE_SERVICES=false UPDATE_YES=false UPDATE_WITH_PACKAGES=false
adopt=false
list=false
targets=()
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --adopt) adopt=true ;;
    --list) list=true ;;
    --allow-major) UPDATE_ALLOW_MAJOR=true ;;
    --include-services) UPDATE_INCLUDE_SERVICES=true ;;
    --yes) UPDATE_YES=true ;;
    --with-packages) UPDATE_WITH_PACKAGES=true ;;
    --help|-h) usage; exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; usage; exit 2 ;;
    *) targets+=("$arg") ;;
  esac
done

if [[ "$list" == true ]]; then
  echo "Managed tools:"
  tool_state_list
  echo "Recorded bundles (membership reflects install/adoption time):"
  for bundle_record in "$(tool_state_dir)"/bundles/*; do
    [[ -f "$bundle_record" ]] || continue
    printf '  %s:' "${bundle_record##*/}"
    while IFS= read -r tool; do
      tool_state_has "$tool" && printf ' %s' "$tool"
    done < "$bundle_record"
    printf '\n'
  done
  exit 0
fi

if [[ "$adopt" == true && ${#targets[@]} -eq 0 ]]; then
  echo "Adoption requires explicit tools or bundles, for example: --adopt cloud" >&2
  exit 2
fi

export PYTHON_PACKAGE_PROFILE="${PYTHON_PACKAGE_PROFILE:-full}" GO_PACKAGE_PROFILE="${GO_PACKAGE_PROFILE:-full}" NODE_PACKAGE_PROFILE="${NODE_PACKAGE_PROFILE:-full}"
for target in "${targets[@]}"; do
  case "$target" in
    ai) PYTHON_PACKAGE_PROFILE=ai; GO_PACKAGE_PROFILE=ai ;;
    python-ai) PYTHON_PACKAGE_PROFILE=ai ;;
    python-core|python-dev) PYTHON_PACKAGE_PROFILE=core ;;
    python-full|python) PYTHON_PACKAGE_PROFILE=full ;;
    go-ai) GO_PACKAGE_PROFILE=ai ;;
    go-core|go-dev) GO_PACKAGE_PROFILE=core ;;
    go-full|go) GO_PACKAGE_PROFILE=full ;;
    node-core|node-dev) NODE_PACKAGE_PROFILE=core ;;
    node-full) NODE_PACKAGE_PROFILE=full ;;
  esac
done

selected=()
if [[ ${#targets[@]} -eq 0 ]]; then
  while IFS= read -r tool; do selected+=("$tool"); done < <(tool_state_list)
else
  while IFS= read -r tool; do
    [[ -n "$tool" ]] && selected+=("$tool")
  done < <(catalog_resolve_targets "${targets[@]}")
fi

for tool in "${selected[@]}"; do
  case "$tool" in identity|git-config|git-signing|ssh-key) continue ;; esac
  valid=false
  for known in "${UPDATEABLE_TOOLS[@]}"; do
    [[ "$tool" != "$known" ]] || valid=true
  done
  if [[ "$valid" != true ]]; then
    echo "Unsupported update target: $tool" >&2
    exit 2
  fi
done

ordered=()
for known in "${UPDATEABLE_TOOLS[@]}" identity git-config git-signing ssh-key; do
  for tool in "${selected[@]}"; do
    [[ "$tool" != "$known" ]] || ordered+=("$tool")
  done
done
if [[ ${#ordered[@]} -eq 0 ]]; then
  echo "No managed tools recorded. Use --adopt TOOL or --adopt BUNDLE for existing installations."
  exit 0
fi

if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "$(tool_state_dir)"
  lock_dir="$(tool_state_dir)/update.lock"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    echo "Another update is running, or a stale lock needs review: $lock_dir" >&2
    exit 1
  fi
  trap 'rmdir "$lock_dir"' EXIT
  log_dir="${TOOL_SHED_LOG_DIR:-$HOME/.tool-shed/logs}"
  mkdir -p "$log_dir"
  log_file="$log_dir/update-$(date +%Y%m%d-%H%M%S)-$$.log"
  exec > >(tee -a "$log_file") 2>&1
  echo "Full log: $log_file"
fi

successful=0
skipped=0
failures=0
export TOOL_SHED_UPDATE_REFRESHED=false
for tool in "${ordered[@]}"; do
  echo "==> $tool"
  if [[ "$adopt" == true ]]; then
    case "$tool" in
      identity|git-config|git-signing|ssh-key) echo "Not applicable: $tool"; skipped=$((skipped + 1)); continue ;;
    esac
    if tool_state_has "$tool"; then
      echo "Already managed: $tool"
      skipped=$((skipped + 1))
    elif ! catalog_tool_present "$tool"; then
      echo "Not installed: $tool"
      skipped=$((skipped + 1))
    elif [[ "$DRY_RUN" == true ]]; then
      echo "DRY RUN: would adopt $tool from $(catalog_tool_update_source "$tool")."
      successful=$((successful + 1))
    elif (set -e; tool_state_record "$tool"); then
      echo "Adopted: $tool"
      successful=$((successful + 1))
    else
      echo "Adoption failed: $tool"
      failures=$((failures + 1))
    fi
    continue
  fi

  if [[ "$TOOL_SHED_UPDATE_REFRESHED" != true && "$DRY_RUN" != true ]] && tool_state_read "$tool" && catalog_tool_present "$tool"; then
    case "$STATE_MANAGER" in
      apt|brew-formula|brew-cask|winget|winget-store)
        if catalog_refresh_latest_metadata; then
          TOOL_SHED_UPDATE_REFRESHED=true
        else
          echo "Package metadata refresh failed; no package updates attempted."
          exit 1
        fi
        ;;
    esac
  fi
  status=0
  TOOL_SHED_UPDATE_INTERNAL=true bash "$REPO_ROOT/$tool/update.sh" || status=$?
  case "$status" in
    0) successful=$((successful + 1)) ;;
    3) skipped=$((skipped + 1)) ;;
    *) echo "FAILED: $tool (exit $status)"; failures=$((failures + 1)) ;;
  esac
done

if [[ "$adopt" == true ]]; then
  for target in "${targets[@]}"; do tool_state_record_bundle "$target"; done
fi
echo "Summary: $successful successful, $skipped skipped, $failures failed."
[[ "$failures" == 0 ]]