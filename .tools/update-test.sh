#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Update safety tests
# ============================================================
#
# Purpose:
#   Exercise managed updates using temporary state and mocked commands.
#
# Notes:
#   No real package manager, service, or network operation is performed.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT
export HOME="$temporary/home"
export TOOL_SHED_STATE_DIR="$temporary/state"
export TOOL_SHED_LOG_DIR="$temporary/logs"
export TOOL_SHED_OS_OVERRIDE=Linux
export MOCK_LOG="$temporary/commands"
export MOCK_INSTALLED='jq curl'
export MOCK_VERSION=1.6.0 MOCK_CANDIDATE=1.7.0
unset BASH_ENV TOOL_SHED_UPDATE_INTERNAL
mkdir -p "$HOME"
touch "$MOCK_LOG"

id() { if [[ "${1:-}" == -u ]]; then echo 0; else command id "$@"; fi; }
jq() { echo jq-1.6.0; }
curl() {
  if [[ "${1:-}" == --version ]]; then
    echo 'curl 1.6.0'
  elif [[ "${MOCK_DOWNLOADS:-false}" == true ]]; then
    case "$2" in
      */stable.txt) echo v1.7.0 ;;
      *.sha256) printf '%064d\n' 0 ;;
      *) printf 'corrupt release' > "$4" ;;
    esac
  else
    echo "Unexpected network call: $*" >&2
    return 99
  fi
}
dpkg-query() {
  local package="${!#}"
  [[ " $MOCK_INSTALLED " == *" $package "* ]] || return 1
  if [[ "$*" == *db:Status-Status* ]]; then
    printf installed
  else
    printf '%s' "$MOCK_VERSION"
  fi
}
apt-cache() { printf '  Candidate: %s\n' "$MOCK_CANDIDATE"; }
apt-mark() { printf '%s' "${MOCK_HELD:-}"; }
apt-get() {
  printf '%s\n' "$*" >> "$MOCK_LOG"
  [[ "$*" != *"${MOCK_FAIL_TOOL:-__never__}"* ]]
}
install() { echo 'Unexpected binary installation' >> "$MOCK_LOG"; return 99; }
export -f id jq curl dpkg-query apt-cache apt-mark apt-get install

source .tools/update-runtime.sh

echo 'Testing read-only adoption and empty state'
output="$(bash update.sh --dry-run)"
[[ "$output" == *'No managed tools recorded'* ]]
bash update.sh --adopt jq --dry-run
[[ ! -e "$TOOL_SHED_STATE_DIR" ]]
[[ ! -e "$TOOL_SHED_LOG_DIR" ]]
[[ ! -s "$MOCK_LOG" ]]
if bash update.sh --adopt >/dev/null 2>&1; then exit 1; fi
if bash update.sh ../escape --dry-run >/dev/null 2>&1; then exit 1; fi

echo 'Testing successful adoption and state metadata'
bash update.sh --adopt jq curl
tool_state_read jq
[[ "$STATE_MANAGER" == apt && "$STATE_PACKAGE" == jq && "$STATE_VERSION" == "$MOCK_VERSION" ]]
[[ ! -s "$MOCK_LOG" ]]

echo 'Testing installed-only selection, deduplication, and one metadata refresh'
output="$(bash update.sh cloud jq curl)"
[[ "$output" == *'2 successful'* && "$output" == *'0 failed'* ]]
[[ "$(grep -c '^update$' "$MOCK_LOG")" == 1 ]]
[[ "$(grep -c -- '-- jq$' "$MOCK_LOG")" == 1 ]]
[[ "$(grep -c -- '-- curl$' "$MOCK_LOG")" == 1 ]]
[[ "$(wc -l < "$MOCK_LOG")" == 3 ]]

echo 'Testing default selection and write-free managed dry runs'
before="$(cksum "$TOOL_SHED_STATE_DIR/tools/jq")"
output="$(bash jq/update.sh --dry-run)"
[[ "$output" == *'1 successful'* ]]
[[ "$(cksum "$TOOL_SHED_STATE_DIR/tools/jq")" == "$before" ]]
[[ "$(wc -l < "$MOCK_LOG")" == 3 ]]
output="$(bash update.sh --dry-run)"
[[ "$output" == *'2 successful'* ]]

echo 'Testing missing installations and changed executable paths'
output="$(MOCK_INSTALLED='' bash jq/update.sh --dry-run)"
[[ "$output" == *'source no longer matches'* ]]
printf 'apt\tjq\t-\tnone\t/changed/jq\t1.6.0\n' > "$TOOL_SHED_STATE_DIR/tools/jq"
output="$(bash jq/update.sh --dry-run)"
[[ "$output" == *'executable changed'* ]]
tool_state_record jq

echo 'Testing package holds, local pins, and major-version restrictions'
output="$(MOCK_HELD=jq bash jq/update.sh --dry-run)"
[[ "$output" == *'is held'* ]]
mkdir -p "$TOOL_SHED_STATE_DIR/pins"
touch "$TOOL_SHED_STATE_DIR/pins/jq"
output="$(bash jq/update.sh --dry-run)"
[[ "$output" == *'is pinned'* ]]
rm "$TOOL_SHED_STATE_DIR/pins/jq"
output="$(MOCK_CANDIDATE=2.0.0 bash jq/update.sh)"
[[ "$output" == *'requires --allow-major'* ]]
output="$(MOCK_CANDIDATE=2.0.0 bash jq/update.sh --allow-major)"
[[ "$output" == *'1 successful'* ]]

echo 'Testing continuation and nonzero status after partial failures'
status=0
output="$(MOCK_FAIL_TOOL=curl bash update.sh curl jq)" || status=$?
[[ "$status" == 1 ]]
[[ "$output" == *'1 successful, 0 skipped, 1 failed'* ]]

echo 'Testing service confirmation and configuration preservation'
printf 'apt\tpostgresql\t-\tnone\t-\t1.6.0\n' > "$TOOL_SHED_STATE_DIR/tools/postgres"
output="$(MOCK_INSTALLED=postgresql bash postgres/update.sh --dry-run)"
[[ "$output" == *'requires --include-services --yes'* ]]
output="$(MOCK_INSTALLED=postgresql bash postgres/update.sh --dry-run --include-services --yes)"
[[ "$output" == *'1 successful'* ]]
output="$(bash identity/update.sh --dry-run)"
[[ "$output" == *'credentials are unchanged'* ]]

echo 'Testing corrupt binary downloads fail before installation'
printf 'direct\t-\t-\tnone\t/usr/local/bin/kubectl\tv1.6.0\n' > "$TOOL_SHED_STATE_DIR/tools/kubectl"
status=0
MOCK_DOWNLOADS=true bash .tools/update-download.sh kubectl > "$temporary/download-output" 2>&1 || status=$?
[[ "$status" != 0 ]]
grep -Fq 'Checksum mismatch' "$temporary/download-output"
if grep -Fq 'Unexpected binary installation' "$MOCK_LOG"; then exit 1; fi

echo 'Testing recorded profiles, state cleanup, and dry-run cleanup guards'
MOCK_INSTALLED='python3' PYTHON_PACKAGE_PROFILE=ai tool_state_record python3
tool_state_read python3
[[ "$STATE_PROFILE" == ai ]]
DRY_RUN=true tool_state_remove python3
tool_state_has python3
tool_state_remove python3
! tool_state_has python3
DRY_RUN=true tool_state_record_bundle cloud
[[ ! -e "$TOOL_SHED_STATE_DIR/bundles" ]]
tool_state_record_bundle cloud
grep -Fxq jq "$TOOL_SHED_STATE_DIR/bundles/cloud"

echo 'Testing every installable module has a read-only update entrypoint'
for module in */install.sh; do
  test -f "${module%/install.sh}/update.sh"
done
for bundle in full cloud services ai; do
  bash update.sh "$bundle" --dry-run > /dev/null
done

echo 'Testing install state hooks without executing real installers'
(
  source .tools/module-runtime.sh
  present=false
  catalog_tool_present() { [[ "$present" == true ]]; }
  module_install_impl() { present=true; }
  tool_state_has() { return 1; }
  tool_state_record() { echo "$1" > "$temporary/install-record"; }
  module_install jq
  [[ "$(< "$temporary/install-record")" == jq ]]
  rm "$temporary/install-record"
  module_install jq
  [[ ! -e "$temporary/install-record" ]]
)
export FAILED_INSTALL_RECORD="$temporary/failed-install-record"
status=0
bash -euo pipefail -c '
  source .tools/module-runtime.sh
  module_install_impl() { false; echo unexpected > "$FAILED_INSTALL_RECORD"; }
  tool_state_record() { echo unexpected > "$FAILED_INSTALL_RECORD"; }
  module_install jq
' || status=$?
[[ "$status" != 0 && ! -e "$FAILED_INSTALL_RECORD" ]]

echo 'Testing Homebrew and winget command shapes with mocks'
(
  export TOOL_SHED_OS_OVERRIDE=Darwin DRY_RUN=false
  source .tools/update-runtime.sh
  STATE_MANAGER=brew-formula
  tool_package_specs() { printf 'brew-formula\tjq\n'; }
  catalog_package_installed() { return 0; }
  catalog_package_version() { echo 1.6.0; }
  catalog_package_latest() { echo 1.7.0; }
  brew() { [[ "$*" == 'list --pinned' ]] || [[ "$*" == 'upgrade --formula jq' ]]; }
  update_mac jq
)
(
  export TOOL_SHED_OS_OVERRIDE=Windows_NT DRY_RUN=false
  source .tools/update-runtime.sh
  STATE_MANAGER=winget-store STATE_SOURCE=msstore
  tool_package_specs() { printf 'winget-store\t9NJNWW8PVKMN\tmsstore\n'; }
  catalog_package_installed() { return 0; }
  catalog_package_version() { echo 1.6.0; }
  catalog_package_latest() { echo 1.7.0; }
  winget() { [[ "$*" == 'upgrade --exact --id 9NJNWW8PVKMN --disable-interactivity --accept-source-agreements --accept-package-agreements --source msstore' ]]; }
  update_windows julia
)

echo 'Update safety tests passed.'