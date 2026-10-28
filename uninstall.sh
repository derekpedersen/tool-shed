#!/usr/bin/env bash

# ============================================================
# Tool-shed uninstaller
# ============================================================
#
# Purpose:
#   Bootstrap and run an explicitly targeted tool-shed uninstall.
#
# Notes:
#   A tool or bundle target is required to prevent accidental full removal.
# ============================================================

set -euo pipefail

usage() {
	echo "Usage: bash uninstall.sh [full|cloud|services|ai|TOOL ...] [--dry-run]"
	echo "A tool or bundle target is required. Preview removals with --dry-run."
}

targets=()
for arg in "$@"; do
	case "$arg" in
		--dry-run|-n) ;;
		--help|-h) usage; exit 0 ;;
		-*) ;;
		*) targets+=("$arg") ;;
	esac
done

if [[ ${#targets[@]} -eq 0 ]]; then
	echo "An explicit uninstall target is required; refusing to default to the full bundle." >&2
	usage >&2
	exit 2
fi

bootstrap_from_github() {
	if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
		echo "curl and tar are required to bootstrap the tool-shed uninstaller." >&2
		return 1
	fi

	local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
	local ref="${TOOL_SHED_REF:-main}"
	local extracted_dir rc
	BOOTSTRAP_TMPDIR="$(mktemp -d)" || return 1
	trap '[[ -z "${BOOTSTRAP_TMPDIR:-}" ]] || rm -rf "$BOOTSTRAP_TMPDIR"' EXIT

	echo "Downloading tool-shed uninstaller from github.com/$repo ($ref)..." >&2
	if ! curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$BOOTSTRAP_TMPDIR/tool-shed.tar.gz"; then
		echo "Could not download tool-shed repository archive." >&2
		return 1
	fi
	if ! tar -xzf "$BOOTSTRAP_TMPDIR/tool-shed.tar.gz" -C "$BOOTSTRAP_TMPDIR"; then
		echo "Could not extract tool-shed repository archive." >&2
		return 1
	fi
	extracted_dir="$(find "$BOOTSTRAP_TMPDIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print -quit)"
	if [[ -z "$extracted_dir" || ! -f "$extracted_dir/.tools/uninstall.sh" ]]; then
		echo "Downloaded archive does not contain .tools/uninstall.sh." >&2
		return 1
	fi

	rc=0
	TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/uninstall.sh" "$@" || rc=$?
	rm -rf "$BOOTSTRAP_TMPDIR"
	BOOTSTRAP_TMPDIR=""
	return "$rc"
}

SCRIPT_PATH="${BASH_SOURCE:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || pwd)"
if [[ -f "$SCRIPT_DIR/.tools/uninstall.sh" ]]; then
	exec bash "$SCRIPT_DIR/.tools/uninstall.sh" "$@"
fi

if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == 1 ]]; then
	echo "Required uninstaller files are missing after bootstrap." >&2
	exit 1
fi

bootstrap_from_github "$@"