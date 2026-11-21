#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tool catalog export
# ============================================================
#
# Purpose:
#   Export platform tool package manager specs as JSON so Go backends
#   can consume shell-defined catalog data without duplication.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$SCRIPT_DIR/tool-catalog.sh"

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

printf '{'
printf '"platform":"%s",' "$(json_escape "$TOOL_CATALOG_PLATFORM")"
printf '"toolSpecs":{'

first_tool=true
for tool in "${UPDATEABLE_TOOLS[@]}"; do
  specs=()
  while IFS=$'\t' read -r manager package source; do
    [[ -n "$manager" ]] || continue
    specs+=("$manager|$package|${source:-}")
  done < <(tool_package_specs "$tool")

  if [[ ${#specs[@]} -eq 0 ]]; then
    continue
  fi

  if [[ "$first_tool" == true ]]; then
    first_tool=false
  else
    printf ','
  fi

  printf '"%s":[' "$(json_escape "$tool")"
  first_spec=true
  for spec in "${specs[@]}"; do
    manager="${spec%%|*}"
    rest="${spec#*|}"
    package="${rest%%|*}"
    source="${rest#*|}"
    if [[ "$first_spec" == true ]]; then
      first_spec=false
    else
      printf ','
    fi
    printf '{"manager":"%s","package":"%s","source":"%s"}' \
      "$(json_escape "$manager")" \
      "$(json_escape "$package")" \
      "$(json_escape "$source")"
  done
  printf ']'
done

printf '}'
printf '}'
printf '\n'
