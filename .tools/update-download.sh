#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Verified upstream update worker
# ============================================================
#
# Purpose:
#   Isolate download failures from the controller's continue-on-error loop.
#
# Notes:
#   Release metadata and binaries are fetched only during real updates.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/update-runtime.sh"
[[ $# == 1 ]] || { echo "Usage: update-download.sh TOOL" >&2; exit 2; }
tool_state_read "$1"

update_nvm() (
  set -euo pipefail
  local directory="${NVM_DIR:-$HOME/.nvm}" metadata version expected actual
  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "DRY RUN: would fetch an allowed NVM release from nvm-sh/nvm, check Git object integrity, and preserve local changes."
    return 0
  fi
  command -v git >/dev/null 2>&1
  command -v jq >/dev/null 2>&1
  if [[ ! -d "$directory/.git" || -n "$(git -C "$directory" status --porcelain)" ]]; then
    update_skip "NVM is not a clean Git installation at $directory; refusing to overwrite it."
    return 3
  fi
  metadata="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest)"
  version="$(jq -er .tag_name <<< "$metadata")"
  [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
  update_version_allowed "$STATE_VERSION" "$version" || { update_skip "NVM version change requires --allow-major."; return 3; }
  metadata="$(curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/git/ref/tags/$version")"
  expected="$(jq -er .object.sha <<< "$metadata")"
  git -C "$directory" -c transfer.fsckObjects=true fetch --no-tags https://github.com/nvm-sh/nvm.git "refs/tags/$version"
  actual="$(git -C "$directory" rev-parse FETCH_HEAD)"
  [[ "$actual" == "$expected" ]]
  git -C "$directory" checkout --detach "$actual"
)

update_aws() (
  set -euo pipefail
  local fingerprint=FB5DB77FD5C118B80511ADA8A6310ACC4672475C architecture temporary signature version
  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "DRY RUN: would verify the AWS CLI installer with its pinned signing fingerprint before updating /usr/local/aws-cli."
    return 0
  fi
  if [[ "$STATE_PATH" != /usr/local/bin/aws || "$(readlink -f "$STATE_PATH")" != /usr/local/aws-cli/* ]]; then
    update_skip "AWS CLI is not the standard /usr/local/aws-cli installation."
    return 3
  fi
  if ! command -v gpg >/dev/null 2>&1 || ! gpg --list-keys "$fingerprint" >/dev/null 2>&1; then
    update_skip "Import the official AWS CLI signing key ($fingerprint) from AWS documentation before updating."
    return 3
  fi
  case "$(uname -m)" in
    x86_64) architecture=x86_64 ;;
    aarch64|arm64) architecture=aarch64 ;;
    *) update_skip "Unsupported AWS architecture."; return 3 ;;
  esac
  temporary="$(mktemp -d)"
  trap 'rm -rf "$temporary"' EXIT
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$architecture.zip" -o "$temporary/aws.zip"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$architecture.zip.sig" -o "$temporary/aws.zip.sig"
  signature="$(gpg --status-fd 1 --verify "$temporary/aws.zip.sig" "$temporary/aws.zip")"
  grep -Fq "[GNUPG:] VALIDSIG $fingerprint " <<< "$signature"
  unzip -q "$temporary/aws.zip" -d "$temporary"
  version="$("$temporary/aws/dist/aws" --version)"
  update_version_allowed "$STATE_VERSION" "$version" || { update_skip "AWS CLI version change requires --allow-major."; return 3; }
  update_privileged "$temporary/aws/install" --update --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin
)

case "$1" in
  nvm) update_nvm ;;
  aws) update_aws ;;
  *)
    if [[ "$TOOL_CATALOG_PLATFORM" == mac && "$1" == scala ]]; then
      source "$SCRIPT_DIR/linux.sh"
    fi
    update_linux_direct "$1"
    ;;
esac