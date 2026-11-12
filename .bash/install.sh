#!/usr/bin/env bash
set -euo pipefail

# The installer concatenates the selected helper files into a single managed
# file next to the user's shell profile (e.g. ~/.tool-shed-bash-helpers) and
# sources that file from the profile. This keeps the profile self-contained:
# no external repo path or temp directory is referenced after install.

bootstrap_from_github() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to bootstrap bash helper files from GitHub."
    return 1
  fi

  local repo="${TOOL_SHED_REPO:-derekpedersen/tool-shed}"
  local ref="${TOOL_SHED_REF:-main}"
  local tmpdir
  local archive
  local extracted_dir
  local rc

  tmpdir="$(mktemp -d)"
  archive="$tmpdir/tool-shed.tar.gz"

  echo "Bootstrapping tool-shed bash helper installer from github.com/$repo ($ref)..."
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" -o "$archive"
  tar -xzf "$archive" -C "$tmpdir"

  extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/.bash/install.sh" ]]; then
    echo "Bootstrap failed: could not find .bash/install.sh in downloaded archive."
    rm -rf "$tmpdir"
    return 1
  fi

  TOOL_SHED_BOOTSTRAPPED=1 TOOL_SHED_REF="$ref" TOOL_SHED_REPO="$repo" bash "$extracted_dir/.bash/install.sh" "$@"
  rc=$?
  rm -rf "$tmpdir"
  return $rc
}

# BASH_SOURCE is unset when piped via curl; fall back to cwd so bootstrap runs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHELL_NAME="${SHELL:-}"
MARKER_BEGIN="# >>> tool-shed/bash helpers >>>"
MARKER_END="# <<< tool-shed/bash helpers <<<"
LEGACY_LINE="# Added by scripts/bash/install.sh"

if ! find "$REPO_ROOT" -mindepth 2 -maxdepth 2 -type f -name 'bash.sh' | grep -q .; then
  if [[ "${TOOL_SHED_BOOTSTRAPPED:-0}" == "1" ]]; then
    echo "No helper modules found in $REPO_ROOT and bootstrap already ran."
    exit 1
  fi

  bootstrap_from_github "$@"
  exit $?
fi

if [[ "$SHELL_NAME" == *"zsh"* ]]; then
  PROFILE_FILE="$HOME/.zshrc"
elif [[ "$SHELL_NAME" == *"bash"* ]]; then
  PROFILE_FILE="$HOME/.bashrc"
else
  PROFILE_FILE="$HOME/.profile"
fi

if [[ ! -f "$PROFILE_FILE" ]]; then
  touch "$PROFILE_FILE"
fi

helper_modules=()
while IFS= read -r file; do
  helper_modules+=("$(basename "$(dirname "$file")")")
done < <(find "$REPO_ROOT" -mindepth 2 -maxdepth 2 -type f -name 'bash.sh' | sort)

if ((${#helper_modules[@]} == 0)); then
  echo "No helper modules found in $REPO_ROOT"
  exit 0
fi

read_existing_selection() {
  local file="$1"
  local selection=""

  if [[ ! -f "$file" ]]; then
    echo ""
    return
  fi

  awk -v start="$MARKER_BEGIN" -v end="$MARKER_END" '
    $0 == start { inblock = 1; next }
    inblock && $0 ~ /^# selected:/ { print substr($0, 11); exit }
    $0 == end { exit }
  ' "$file" 2>/dev/null | tr -d '\r'
}

remove_profile_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"

  if [[ ! -f "$file" ]]; then
    return
  fi

  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

remove_legacy_profile_block() {
  local file="$1"
  local legacy="$LEGACY_LINE"

  if [[ ! -f "$file" ]]; then
    return
  fi

  awk -v legacy="$legacy" '
    $0 == legacy { skip = 1; next }
    skip && $0 ~ /^for file in / { next }
    skip && $0 ~ /^  \[ -f / { next }
    skip && $0 ~ /^\[ -f / { next }
    skip && $0 ~ /^done$/ { skip = 0; next }
    skip && $0 ~ /^$/ { next }
    !skip { print }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

remove_profile_block "$PROFILE_FILE" "$MARKER_BEGIN" "$MARKER_END"
remove_legacy_profile_block "$PROFILE_FILE"

selected_files=()
existing_selection="$(read_existing_selection "$PROFILE_FILE")"
if [[ -n "$existing_selection" ]]; then
  for file in $existing_selection; do
    normalized="$file"
    if [[ "$file" == */bash.sh ]]; then
      normalized="${file%%/*}"
    elif [[ "$file" == *.bash ]]; then
      normalized="${file%.bash}"
    fi
    selected_files+=("$normalized")
  done
fi

deduped_selection=()
for selected in ${selected_files[@]+"${selected_files[@]}"}; do
  already_selected=0
  for existing in ${deduped_selection[@]+"${deduped_selection[@]}"}; do
    if [[ "$existing" == "$selected" ]]; then
      already_selected=1
      break
    fi
  done
  if (( already_selected == 0 )); then
    deduped_selection+=("$selected")
  fi
done
selected_files=()
if ((${#deduped_selection[@]} > 0)); then
  for selected in ${deduped_selection[@]+"${deduped_selection[@]}"}; do
    selected_files+=("$selected")
  done
fi

if [[ -t 0 ]]; then
  available_missing=()
  for file in ${helper_modules[@]+"${helper_modules[@]}"}; do
    already_selected=0
    for selected in ${selected_files[@]+"${selected_files[@]}"}; do
      if [[ "$selected" == "$file" ]]; then
        already_selected=1
        break
      fi
    done
    if (( already_selected == 0 )); then
      available_missing+=("$file")
    fi
  done

  if (( ${#available_missing[@]} > 0 )); then
    echo "New helper modules available:"
    for i in "${!helper_modules[@]}"; do
      printf '  %2d) %s\n' "$((i + 1))" "${helper_modules[$i]}"
    done
    printf 'Select the modules to enable (blank = all, or enter a comma-separated list like 1,3): '
    read -r response

    if [[ -n "$response" ]]; then
      selected_files=()
      IFS=',' read -ra picks <<< "$response"
      for pick in ${picks[@]+"${picks[@]}"}; do
        pick="${pick//[[:space:]]/}"
        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#helper_modules[@]} )); then
          selected_files+=("${helper_modules[$((pick - 1))]}")
        fi
      done

      if ((${#selected_files[@]} == 0)); then
        selected_files=("${helper_modules[@]}")
      fi
    else
      selected_files=("${helper_modules[@]}")
    fi
  elif ((${#selected_files[@]} == 0)); then
    selected_files=("${helper_modules[@]}")
  fi
else
  if ((${#selected_files[@]} == 0)); then
    selected_files=("${helper_modules[@]}")
  fi
fi

if [[ "$(uname -s)" == "Darwin" ]] && [[ "$SHELL_NAME" == *"bash"* ]]; then
  BASH_PROFILE="$HOME/.bash_profile"
  if [[ ! -f "$BASH_PROFILE" ]]; then
    touch "$BASH_PROFILE"
  fi

  if ! grep -Fq "~/.bashrc" "$BASH_PROFILE" && ! grep -Fq ". ~/.bashrc" "$BASH_PROFILE" && ! grep -Fq "source ~/.bashrc" "$BASH_PROFILE"; then
    printf '\nif [ -f ~/.bashrc ]; then\n  . ~/.bashrc\nfi\n' >> "$BASH_PROFILE"
  fi
fi

selected_list="${selected_files[*]}"

# Managed helpers file lives next to the profile (e.g. ~/.tool-shed-bash-helpers)
HELPERS_FILE="${TOOL_SHED_HELPERS_FILE:-$HOME/.tool-shed-bash-helpers}"
LEGACY_HELPERS_FILE="$HOME/.scripts-bash-helpers"

{
  echo "# Managed by tool-shed/.bash/install.sh. Do not edit directly."
  echo "# Rerun the installer to update: https://github.com/derekpedersen/tool-shed"
  echo "# selected: $selected_list"
  echo
  for selected in ${selected_files[@]+"${selected_files[@]}"}; do
    file="$REPO_ROOT/$selected/bash.sh"
    if [[ -f "$file" ]]; then
      echo "# ---- begin $selected/bash.sh ----"
      # Ensure a trailing newline even if the source file is missing one,
      # otherwise its last line merges with the following comment marker.
      cat "$file"
      echo
      echo "# ---- end $selected/bash.sh ----"
      echo
    fi
  done
} > "$HELPERS_FILE"

if [[ -f "$LEGACY_HELPERS_FILE" ]]; then
  rm -f "$LEGACY_HELPERS_FILE"
fi

SOURCE_BLOCK=$(cat <<EOF

$MARKER_BEGIN
# selected: $selected_list
[[ -f "$HELPERS_FILE" ]] && source "$HELPERS_FILE"
$MARKER_END
EOF
)

if ! grep -Fq "$MARKER_BEGIN" "$PROFILE_FILE"; then
  printf '%s\n' "$SOURCE_BLOCK" >> "$PROFILE_FILE"
fi

echo "Wrote Bash helpers to $HELPERS_FILE"
echo "Added Bash helper source to $PROFILE_FILE"
if ((${#selected_files[@]} > 0)); then
  printf 'Enabled: %s\n' "${selected_files[*]}"
fi

echo
printf 'Reload your shell with:\n  source "%s"\n' "$PROFILE_FILE"
if [[ "$(uname -s)" == "Darwin" ]] && [[ "$SHELL_NAME" == *"bash"* ]]; then
  printf 'If your terminal uses bash login shells, also reload ~/.bash_profile or open a new terminal.\n'
fi
printf 'Or open a new terminal session to use the helpers.\n'
