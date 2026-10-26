#!/usr/bin/env bash
set -euo pipefail

TOOL_CATALOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
source "$TOOL_CATALOG_DIR/common.sh"

TOOL_CATALOG_OS="${TOOL_SHED_OS_OVERRIDE:-$(uname -s)}"
case "$TOOL_CATALOG_OS" in
  Darwin)
    TOOL_CATALOG_PLATFORM="mac"
    ;;
  Linux)
    TOOL_CATALOG_PLATFORM="linux"
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    TOOL_CATALOG_PLATFORM="windows"
    ;;
  *)
    if [[ -n "${WSL_DISTRO_NAME:-}" || "$(uname -r 2>/dev/null || true)" == *Microsoft* ]]; then
      TOOL_CATALOG_PLATFORM="linux"
    else
      echo "Unsupported OS: $TOOL_CATALOG_OS" >&2
      return 1 2>/dev/null || exit 1
    fi
    ;;
esac

emit_tool_package() {
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}"
}

catalog_resolve_targets() {
  local expanded=()
  local item

  for item in "$@"; do
    if [[ "$item" == "all" ]]; then
      expanded+=("${UPDATEABLE_TOOLS[@]}")
    else
      while IFS= read -r expanded_item; do
        [[ -z "$expanded_item" ]] && continue
        expanded+=("$(canonical_tool_name "$expanded_item")")
      done < <(expand_bundle_item "$item")
    fi
  done

  local result=()
  for item in "${expanded[@]}"; do
    local seen=false
    local existing
    for existing in "${result[@]}"; do
      if [[ "$existing" == "$item" ]]; then
        seen=true
        break
      fi
    done
    [[ "$seen" == true ]] || result+=("$item")
  done

  printf '%s\n' "${result[@]}"
}

tool_package_specs() {
  local tool="$1"

  case "$TOOL_CATALOG_PLATFORM:$tool" in
    linux:git) emit_tool_package apt git ;;
    linux:gpg) emit_tool_package apt gnupg ;;
    linux:curl) emit_tool_package apt curl ;;
    linux:wget) emit_tool_package apt wget ;;
    linux:unzip) emit_tool_package apt unzip ;;
    linux:python3) emit_tool_package apt python3 ;;
    linux:r) emit_tool_package apt r-base ;;
    linux:cpp) emit_tool_package apt build-essential ;;
    linux:java) emit_tool_package apt temurin-25-jdk ;;
    linux:docker)
      emit_tool_package apt docker-ce
      emit_tool_package apt docker-ce-cli
      emit_tool_package apt containerd.io
      emit_tool_package apt docker-buildx-plugin
      emit_tool_package apt docker-compose-plugin
      ;;
    linux:dotnetcore) emit_tool_package apt dotnet-sdk-8.0 ;;
    linux:vscode) emit_tool_package apt code ;;
    linux:gcloud) emit_tool_package apt google-cloud-cli ;;
    linux:az) emit_tool_package apt azure-cli ;;
    linux:jq) emit_tool_package apt jq ;;
    linux:postgres) emit_tool_package apt postgresql ;;
    linux:redis) emit_tool_package apt redis-server ;;
    linux:mysql) emit_tool_package apt mysql-server ;;
    linux:clickhouse) emit_tool_package apt clickhouse-server ;;
    linux:mongodb) emit_tool_package apt mongodb-org ;;
    linux:rabbitmq) emit_tool_package apt rabbitmq-server ;;
    linux:elasticsearch) emit_tool_package apt elasticsearch ;;
    mac:git)
      emit_tool_package brew-formula git
      emit_tool_package brew-formula bash-completion
      emit_tool_package brew-formula vim
      ;;
    mac:gpg) emit_tool_package brew-formula gnupg ;;
    mac:jq) emit_tool_package brew-formula jq ;;
    mac:yq) emit_tool_package brew-formula yq ;;
    mac:helm) emit_tool_package brew-formula helm ;;
    mac:kubectl) emit_tool_package brew-formula kubectl ;;
    mac:golang) emit_tool_package brew-formula go ;;
    mac:java) emit_tool_package brew-cask temurin@25 ;;
    mac:scala) emit_tool_package direct scala-cli ;;
    mac:r) emit_tool_package brew-formula r ;;
    mac:dotnetcore) emit_tool_package brew-cask dotnet-sdk ;;
    mac:vscode) emit_tool_package brew-cask visual-studio-code ;;
    mac:gcloud) emit_tool_package brew-cask google-cloud-sdk ;;
    mac:aws) emit_tool_package brew-formula awscli ;;
    mac:eksctl) emit_tool_package brew-formula eksctl ;;
    mac:az) emit_tool_package brew-formula azure-cli ;;
    mac:doctl) emit_tool_package brew-formula doctl ;;
    mac:unzip) emit_tool_package brew-formula unzip ;;
    mac:wget) emit_tool_package brew-formula wget ;;
    mac:python3) emit_tool_package brew-formula python ;;
    mac:postgres) emit_tool_package brew-formula postgresql@16 ;;
    mac:redis) emit_tool_package brew-formula redis ;;
    mac:mysql) emit_tool_package brew-formula mysql ;;
    mac:clickhouse) emit_tool_package brew-formula clickhouse ;;
    mac:mongodb) emit_tool_package brew-formula mongodb-community ;;
    mac:rabbitmq) emit_tool_package brew-formula rabbitmq ;;
    mac:elasticsearch) emit_tool_package brew-formula elasticsearch ;;
    mac:kafka) emit_tool_package brew-formula kafka ;;
    windows:git) emit_tool_package winget Git.Git ;;
    windows:gpg) emit_tool_package winget GnuPG.GnuPG ;;
    windows:curl) emit_tool_package winget cURL.cURL ;;
    windows:wget) emit_tool_package winget GnuWin32.Wget ;;
    windows:unzip) emit_tool_package winget GnuWin32.UnZip ;;
    windows:python3) emit_tool_package winget Python.Python.3.12 ;;
    windows:nvm) emit_tool_package winget CoreyButler.NVMforWindows ;;
    windows:node) emit_tool_package winget OpenJS.NodeJS.LTS ;;
    windows:golang) emit_tool_package winget GoLang.Go ;;
    windows:java) emit_tool_package winget EclipseAdoptium.Temurin.25.JDK ;;
    windows:cpp) emit_tool_package winget Microsoft.VisualStudio.2022.BuildTools ;;
    windows:rust) emit_tool_package winget Rustlang.Rustup ;;
    windows:scala) emit_tool_package winget VirtusLab.ScalaCLI ;;
    windows:r) emit_tool_package winget RProject.R ;;
    windows:julia) emit_tool_package winget-store 9NJNWW8PVKMN msstore ;;
    windows:kubectl) emit_tool_package winget Kubernetes.kubectl ;;
    windows:helm) emit_tool_package winget Helm.Helm ;;
    windows:docker) emit_tool_package winget Docker.DockerDesktop ;;
    windows:dotnetcore) emit_tool_package winget Microsoft.DotNet.SDK.8 ;;
    windows:vscode) emit_tool_package winget Microsoft.VisualStudioCode ;;
    windows:gcloud) emit_tool_package winget Google.CloudSDK ;;
    windows:aws) emit_tool_package winget Amazon.AWSCLI ;;
    windows:eksctl) emit_tool_package winget Weaveworks.Eksctl ;;
    windows:az) emit_tool_package winget Microsoft.AzureCLI ;;
    windows:doctl) emit_tool_package winget DigitalOcean.Doctl ;;
    windows:jq) emit_tool_package winget jqlang.jq ;;
    windows:yq) emit_tool_package winget MikeFarah.YQ ;;
    windows:postgres) emit_tool_package winget PostgreSQL.PostgreSQL.16 ;;
    windows:redis) emit_tool_package winget Redis.Redis ;;
    windows:mysql) emit_tool_package winget Oracle.MySQL ;;
    windows:clickhouse) emit_tool_package winget ClickHouse.ClickHouse ;;
    windows:mongodb) emit_tool_package winget MongoDB.Server ;;
    windows:rabbitmq) emit_tool_package winget RabbitMQ.RabbitMQ ;;
    windows:elasticsearch) emit_tool_package winget Elastic.Elasticsearch ;;
    windows:kafka) emit_tool_package winget Confluent.Kafka ;;
  esac
}

tool_executable() {
  case "$1" in
    git|gpg|curl|wget|unzip|R|java|kubectl|helm|docker|code|gcloud|aws|eksctl|az|doctl|jq|yq|julia|scala-cli|juliaup|rustc|rustup|Rscript|Rscript.exe|redis-server|mysql|clickhouse|mongod|rabbitmq-server|elasticsearch|kafka-server-start|nvm|node|go|dotnet|psql|cc)
      printf '%s\n' "$1"
      ;;
    python3) printf '%s\n' python3 ;;
    r) printf '%s\n' R ;;
    cpp)
      if [[ "$TOOL_CATALOG_PLATFORM" == "windows" ]]; then
        printf '%s\n' cl
      else
        printf '%s\n' cc
      fi
      ;;
    golang) printf '%s\n' go ;;
    java) printf '%s\n' java ;;
    julia) printf '%s\n' julia ;;
    scala) printf '%s\n' scala-cli ;;
    vscode) printf '%s\n' code ;;
    postgres) printf '%s\n' psql ;;
    mongodb) printf '%s\n' mongod ;;
    rabbitmq) printf '%s\n' rabbitmq-server ;;
    kafka)
      if [[ "$TOOL_CATALOG_PLATFORM" == linux && -x /opt/kafka/bin/kafka-topics.sh ]]; then
        printf '%s\n' /opt/kafka/bin/kafka-topics.sh
      else
        printf '%s\n' kafka-server-start
      fi
      ;;
    *) return 1 ;;
  esac
}

catalog_source_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    export NVM_DIR="$nvm_dir"
    set +u
    . "$nvm_dir/nvm.sh"
    set -u
  fi
}

catalog_package_installed() {
  local manager="$1"
  local package="$2"
  local source="${3:-}"

  case "$manager" in
    apt)
      dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx installed
      ;;
    brew-formula)
      command -v brew >/dev/null 2>&1 && brew list --formula --versions "$package" >/dev/null 2>&1
      ;;
    brew-cask)
      command -v brew >/dev/null 2>&1 && brew list --cask --versions "$package" >/dev/null 2>&1
      ;;
    winget|winget-store)
      if command -v winget >/dev/null 2>&1; then
        local winget_args=(list --exact --id "$package")
        [[ -n "$source" ]] && winget_args+=(--source "$source")
        winget "${winget_args[@]}" 2>/dev/null | grep -Fq "$package"
      else
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac
}

catalog_package_version() {
  local manager="$1"
  local package="$2"
  local source="${3:-}"

  case "$manager" in
    apt)
      dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true
      ;;
    brew-formula)
      brew list --formula --versions "$package" 2>/dev/null | awk '{print $NF}'
      ;;
    brew-cask)
      brew list --cask --versions "$package" 2>/dev/null | awk '{print $NF}'
      ;;
    winget|winget-store)
      local winget_args=(list --exact --id "$package")
      [[ -n "$source" ]] && winget_args+=(--source "$source")
      winget "${winget_args[@]}" 2>/dev/null | awk -v id="$package" '{for (i=1; i<NF; i++) if ($i == id) {print $(i+1); exit}}'
      ;;
  esac
}

catalog_package_latest() {
  local manager="$1"
  local package="$2"
  local source="${3:-}"

  case "$manager" in
    apt)
      apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2; exit}'
      ;;
    brew-formula|brew-cask)
      if ! command -v ruby >/dev/null 2>&1; then
        return 0
      fi
      local brew_type="formula"
      [[ "$manager" == "brew-cask" ]] && brew_type="cask"
      brew info --json=v2 --"$brew_type" "$package" 2>/dev/null | ruby -rjson -e '
        data = JSON.parse(STDIN.read)
        item = (data["formulae"] || data["casks"] || []).first || {}
        version = item["versions"]
        puts(version.is_a?(Hash) ? version["stable"] : item["version"])
      ' 2>/dev/null || true
      ;;
    winget|winget-store)
      local winget_args=(list --upgrade-available --exact --id "$package")
      [[ -n "$source" ]] && winget_args+=(--source "$source")
      winget "${winget_args[@]}" 2>/dev/null | awk -v id="$package" '{for (i=1; i<NF; i++) if ($i == id) {print $(i+2); exit}}'
      ;;
  esac
}

catalog_tool_update_source() {
  local tool="$1"
  local manager package source

  while IFS=$'\t' read -r manager package source; do
    [[ -n "$manager" ]] || continue
    case "$manager" in
      apt) printf '%s\n' "apt:$package"; return 0 ;;
      brew-formula) printf '%s\n' "Homebrew formula:$package"; return 0 ;;
      brew-cask) printf '%s\n' "Homebrew cask:$package"; return 0 ;;
      winget) printf '%s\n' "winget:$package"; return 0 ;;
      winget-store) printf '%s\n' "Microsoft Store:$package"; return 0 ;;
    esac
  done < <(tool_package_specs "$tool")

  case "$tool" in
    nvm|node) printf '%s\n' "NVM" ;;
    rust) printf '%s\n' "rustup" ;;
    julia) printf '%s\n' "Juliaup" ;;
    scala) printf '%s\n' "Scala CLI" ;;
    golang|helm|kubectl|eksctl|doctl|yq|aws) printf '%s\n' "upstream binary" ;;
    *) printf '%s\n' "external or system-managed" ;;
  esac
}

catalog_tool_present() {
  local tool="$1"
  local executable=""
  local manager package source

  [[ "$tool" == "nvm" ]] && catalog_source_nvm
  executable="$(tool_executable "$tool" 2>/dev/null || true)"
  if [[ -n "$executable" ]] && command -v "$executable" >/dev/null 2>&1; then
    return 0
  fi

  while IFS=$'\t' read -r manager package source; do
    [[ -n "$manager" ]] || continue
    if catalog_package_installed "$manager" "$package" "$source"; then
      return 0
    fi
  done < <(tool_package_specs "$tool")

  return 1
}

catalog_tool_installed_version() {
  local tool="$1"
  local executable=""
  local manager package source version=""

  [[ "$tool" == "nvm" || "$tool" == "node" ]] && catalog_source_nvm
  executable="$(tool_executable "$tool" 2>/dev/null || true)"
  if [[ -n "$executable" ]] && command -v "$executable" >/dev/null 2>&1; then
    case "$tool" in
      nvm) version="$(nvm --version 2>/dev/null || true)" ;;
      julia) version="$(julia --version 2>/dev/null || true)" ;;
      juliaup) version="$(juliaup --version 2>/dev/null || true)" ;;
      rust) version="$(rustc --version 2>/dev/null || true)" ;;
      rustup) version="$(rustup --version 2>/dev/null || true)" ;;
      golang) version="$(go version 2>/dev/null || true)" ;;
      java) version="$(java -version 2>&1 | awk 'NR == 1 {print; exit}')" ;;
      r) version="$(R --version 2>/dev/null | awk 'NR == 1 {print; exit}')" ;;
      cpp) version="$("$executable" --version 2>&1 | awk 'NR == 1 {print; exit}')" ;;
      kubectl) version="$(kubectl version --client 2>/dev/null | awk 'NR == 1 {print; exit}')" ;;
      helm) version="$(helm version --short 2>/dev/null || true)" ;;
      docker) version="$(docker --version 2>/dev/null || true)" ;;
      scala) version="$(scala-cli version 2>/dev/null | awk 'NR == 1 {print; exit}')" ;;
      *) version="$("$executable" --version 2>&1 | awk 'NR == 1 {print; exit}')" ;;
    esac
    [[ -n "$version" ]] && { printf '%s\n' "$version"; return 0; }
  fi

  while IFS=$'\t' read -r manager package source; do
    [[ -n "$manager" ]] || continue
    if catalog_package_installed "$manager" "$package" "$source"; then
      version="$(catalog_package_version "$manager" "$package" "$source")"
      [[ -n "$version" ]] && { printf '%s\n' "$version"; return 0; }
    fi
  done < <(tool_package_specs "$tool")

  printf '%s\n' unknown
}

catalog_tool_latest_version() {
  local tool="$1"
  local manager package source latest=""

  while IFS=$'\t' read -r manager package source; do
    [[ -n "$manager" ]] || continue
    if catalog_package_installed "$manager" "$package" "$source"; then
      latest="$(catalog_package_latest "$manager" "$package" "$source")"
      if [[ -n "$latest" ]]; then
        printf '%s\n' "$latest"
        return 0
      fi
    fi
  done < <(tool_package_specs "$tool")

  printf '%s\n' unknown
}

catalog_refresh_latest_metadata() {
  case "$TOOL_CATALOG_PLATFORM" in
    linux)
      if [[ "$(id -u)" == "0" ]]; then
        apt-get update
      elif command -v sudo >/dev/null 2>&1; then
        sudo -n apt-get update
      else
        echo "Cannot refresh apt metadata without root or sudo." >&2
        return 1
      fi
      ;;
    mac)
      brew update
      ;;
    windows)
      winget source update --disable-interactivity
      ;;
  esac
}
