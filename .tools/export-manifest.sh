#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Tool-shed manifest export
# ============================================================
#
# Purpose:
#   Export canonical bundle and target mapping definitions as JSON
#   for consumers that should not duplicate shell runtime lists.
#
# Notes:
#   Bundle arrays are sourced from common.sh so package lists remain
#   single-source and shared across shell and Go paths.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_json_array() {
  local first=true
  printf '['
  for item in "$@"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      printf ','
    fi
    printf '"%s"' "$item"
  done
  printf ']'
}

print_json_string_map() {
  local first=true
  printf '{'
  while [[ $# -gt 0 ]]; do
    local key="$1"
    local value="$2"
    shift 2
    if [[ "$first" == true ]]; then
      first=false
    else
      printf ','
    fi
    printf '"%s":"%s"' "$key" "$value"
  done
  printf '}'
}

printf '{'

printf '"bundles":{'
printf '"full":'; print_json_array "${FULL_BUNDLE[@]}"; printf ','
printf '"cloud":'; print_json_array "${CLOUD_BUNDLE[@]}"; printf ','
printf '"services":'; print_json_array "${SERVICES_BUNDLE[@]}"; printf ','
printf '"ai":'; print_json_array "${AI_BUNDLE[@]}"; printf ','
printf '"software-developer":'; print_json_array "${SOFTWARE_DEVELOPER_BUNDLE[@]}"; printf ','
printf '"data-science":'; print_json_array "${DATA_SCIENCE_BUNDLE[@]}"
printf '},'

printf '"aliases":'
print_json_string_map \
  "juliaup" "julia" \
  "R" "r" \
  "r-lang" "r" \
  "scala-cli" "scala" \
  "rustup" "rust" \
  "c++" "cpp" \
  "jdk" "java" \
  "kubernetes-cli" "kubectl" \
  "google-cloud" "gcloud" \
  "awscli" "aws" \
  "azure" "az" \
  "azure-cli" "az" \
  "digitalocean" "doctl" \
  "doks" "doctl" \
  "dotnet" "dotnetcore" \
  "code" "vscode" \
  "python-core" "python3" \
  "python-full" "python3" \
  "python-ai" "python3" \
  "python" "python3" \
  "go-core" "golang" \
  "go-full" "golang" \
  "go-ai" "golang" \
  "go" "golang" \
  "golang" "golang" \
  "java" "java" \
  "openjdk" "java" \
  "temurin" "java" \
  "node-core" "node" \
  "node-full" "node" \
  "node" "node"
printf ','

printf '"expansions":{'
printf '"full":'; print_json_array "${FULL_BUNDLE[@]}"; printf ','
printf '"cloud":'; print_json_array "${CLOUD_BUNDLE[@]}"; printf ','
printf '"services":'; print_json_array "${SERVICES_BUNDLE[@]}"; printf ','
printf '"ai":'; print_json_array "${AI_BUNDLE[@]}"; printf ','
printf '"software-developer":'; print_json_array "${SOFTWARE_DEVELOPER_BUNDLE[@]}"; printf ','
printf '"data-science":'; print_json_array "${DATA_SCIENCE_BUNDLE[@]}"; printf ','
printf '"python-core":'; print_json_array "python3"; printf ','
printf '"python-full":'; print_json_array "python3"; printf ','
printf '"python-ai":'; print_json_array "python3"; printf ','
printf '"python":'; print_json_array "python3"; printf ','
printf '"go-core":'; print_json_array "golang"; printf ','
printf '"go-full":'; print_json_array "golang"; printf ','
printf '"go-ai":'; print_json_array "golang"; printf ','
printf '"go":'; print_json_array "golang"; printf ','
printf '"node-core":'; print_json_array "node"; printf ','
printf '"node-full":'; print_json_array "node"; printf ','
printf '"node":'; print_json_array "node"
printf '}'

printf '}'
printf '\n'
