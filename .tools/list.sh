#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Installed tool inventory
# ============================================================
#
# Purpose:
#   List locally detected tool-shed tools and their installed versions.
#
# Notes:
#   This read-only controller does not load or invoke update code.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tool-catalog.sh"
source "$SCRIPT_DIR/state.sh"

usage() {
  echo "Usage: bash list.sh [full|cloud|services|ai|all|TOOL ...]"
  echo "Lists detected supported tools, live versions, and management status."
  echo "With no target, checks every supported tool, including optional tools."
}

targets=()
show_help=false
for arg in "$@"; do
  case "$arg" in
    --help|-h) show_help=true ;;
    --list) ;;
    -*) echo "Unsupported list option: $arg" >&2; usage >&2; exit 2 ;;
    *) targets+=("$arg") ;;
  esac
done

if [[ "$show_help" == true ]]; then
  usage
  exit 0
fi

if [[ ${#targets[@]} -eq 0 ]]; then
  selected=("${UPDATEABLE_TOOLS[@]}")
else
  selected=()
  while IFS= read -r tool; do
    [[ -z "$tool" ]] || selected+=("$tool")
  done < <(catalog_resolve_targets "${targets[@]}")
fi

for tool in "${selected[@]}"; do
  supported=false
  case "$tool" in identity|git-config|git-signing|ssh-key) supported=true ;; esac
  for known in "${UPDATEABLE_TOOLS[@]}"; do
    [[ "$tool" != "$known" ]] || supported=true
  done
  if [[ "$supported" != true ]]; then
    echo "Unsupported list target: $tool" >&2
    exit 2
  fi
done

printf '%-18s %-42s %s\n' TOOL VERSION MANAGEMENT
printf '%-18s %-42s %s\n' '------------------' '------------------------------------------' '----------------'
listed=0
for tool in "${selected[@]}"; do
  case "$tool" in
    identity|git-config|git-signing|ssh-key)
      printf '%-18s %-42s %s\n' "$tool" "not applicable" "configuration only"
      listed=$((listed + 1))
      continue
      ;;
  esac
  if ! catalog_tool_present "$tool"; then
    continue
  fi
  version="$(catalog_tool_installed_version "$tool" 2>/dev/null || true)"
  version="${version%%$'\n'*}"
  version="${version//$'\t'/ }"
  version="${version//$'\r'/ }"
  version="${version//$'\033'/}"
  [[ -n "$version" ]] || version=unknown
  management=unmanaged
  tool_state_has "$tool" && management=managed
  printf '%-18s %-42.42s %s\n' "$tool" "$version" "$management"
  listed=$((listed + 1))
done

if (( listed == 0 )); then
  echo "No supported installed tools detected for the requested targets."
fi

if [[ ${#targets[@]} -eq 0 ]]; then
  echo
  echo "Recorded bundles (historical membership, not a current inventory):"
  has_bundle=false
  for bundle_record in "$(tool_state_dir)"/bundles/*; do
    [[ -f "$bundle_record" ]] || continue
    has_bundle=true
    printf '  %s:' "${bundle_record##*/}"
    while IFS= read -r tool; do
      tool_state_has "$tool" && printf ' %s' "$tool"
    done < "$bundle_record"
    printf '\n'
  done
  [[ "$has_bundle" == true ]] || echo "  (none)"
fi