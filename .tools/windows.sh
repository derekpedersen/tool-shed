#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Windows installer support
# ============================================================
#
# Purpose:
#   Install and uninstall developer tooling on native Windows 11+ using
#   winget. This file is sourced by the repo's installer entrypoints when the
#   current host reports a Windows shell (PowerShell, Git Bash/MSYS, or a
#   native Windows bash environment).
#
# Notes:
#   This is intentionally narrow: it supports the repo's managed bundle names
#   and uses winget for the standard Windows package manager flow.
# ============================================================

ensure_windows_pkg_manager() {
  if ! command -v winget >/dev/null 2>&1; then
    echo "winget is required for Windows installs but was not found in PATH."
    return 1
  fi
}

install_winget_if_missing() {
  local package_id="$1"
  local binary_name="${2:-$package_id}"

  if command -v "$binary_name" >/dev/null 2>&1; then
    return 0
  fi

  if winget list --exact --id "$package_id" >/dev/null 2>&1; then
    return 0
  fi

  winget install --id "$package_id" --exact --silent --disable-interactivity --accept-source-agreements --accept-package-agreements
}

install_winget_with_override_if_missing() {
  local package_id="$1"
  local override_args="$2"

  if winget list --exact --id "$package_id" >/dev/null 2>&1; then
    return 0
  fi

  winget install --id "$package_id" --exact --silent --disable-interactivity --accept-source-agreements --accept-package-agreements --override "$override_args"
}

remove_winget_if_present() {
  local package_id="$1"

  if ! winget list --exact --id "$package_id" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: winget uninstall --id $package_id --exact --silent --disable-interactivity"
    return 0
  fi

  winget uninstall --id "$package_id" --exact --silent --disable-interactivity || true
}

install_windows() {
  WINDOWS_SKIPPED_COUNT=0
  echo "Detected Windows 11+"

  ensure_windows_pkg_manager || return 1

  for pkg in "$@"; do
    case "$pkg" in
      git)
        install_winget_if_missing "Git.Git" "git"
        ;;
      gpg)
        install_winget_if_missing "GnuPG.GnuPG" "gpg"
        ;;
      curl)
        install_winget_if_missing "cURL.cURL" "curl"
        ;;
      wget)
        install_winget_if_missing "GnuWin32.Wget" "wget"
        ;;
      unzip)
        install_winget_if_missing "GnuWin32.UnZip" "unzip"
        ;;
      python3)
        install_winget_if_missing "Python.Python.3.12" "python"
        install_python_dev_packages "python"
        ;;
      nvm)
        install_winget_if_missing "CoreyButler.NVMforWindows" "nvm"
        ;;
      node)
        install_winget_if_missing "OpenJS.NodeJS.LTS" "node"
        install_node_dev_packages "node"
        ;;
      golang)
        install_winget_if_missing "GoLang.Go" "go"
        install_go_dev_packages "go"
        ;;
      java)
        install_winget_if_missing "EclipseAdoptium.Temurin.25.JDK" "javac"
        ;;
      cpp)
        install_winget_with_override_if_missing "Microsoft.VisualStudio.2022.BuildTools" "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100"
        ;;
      rust)
        export PATH="$HOME/.cargo/bin:$PATH"
        install_winget_if_missing "Rustlang.Rustup" "rustup"
        if command -v rustup >/dev/null 2>&1; then
          ensure_rustup_default
        fi
        ;;
      scala)
        install_winget_if_missing "VirtusLab.ScalaCLI" "scala-cli"
        ;;
      r)
        install_winget_if_missing "RProject.R" "R"
        ;;
      kubectl)
        install_winget_if_missing "Kubernetes.kubectl" "kubectl"
        ;;
      kubernetes-cli)
        install_winget_if_missing "Kubernetes.kubectl" "kubectl"
        ;;
      helm)
        install_winget_if_missing "Helm.Helm" "helm"
        ;;
      docker)
        install_winget_if_missing "Docker.DockerDesktop" "docker"
        ;;
      dotnetcore|dotnet)
        install_winget_if_missing "Microsoft.DotNet.SDK.8" "dotnet"
        ;;
      vscode|code)
        install_winget_if_missing "Microsoft.VisualStudioCode" "code"
        ;;
      gcloud|google-cloud)
        install_winget_if_missing "Google.CloudSDK" "gcloud"
        ;;
      aws|awscli)
        install_winget_if_missing "Amazon.AWSCLI" "aws"
        ;;
      eksctl)
        install_winget_if_missing "Weaveworks.Eksctl" "eksctl"
        ;;
      az|azure|azure-cli)
        install_winget_if_missing "Microsoft.AzureCLI" "az"
        ;;
      doctl|digitalocean|doks)
        install_winget_if_missing "DigitalOcean.Doctl" "doctl"
        ;;
      jq)
        install_winget_if_missing "jqlang.jq" "jq"
        ;;
      yq)
        install_winget_if_missing "MikeFarah.YQ" "yq"
        ;;
      postgres)
        install_winget_if_missing "PostgreSQL.PostgreSQL.16" "psql"
        ;;
      redis)
        install_winget_if_missing "Redis.Redis" "redis-server"
        ;;
      mysql)
        install_winget_if_missing "Oracle.MySQL" "mysql"
        ;;
      clickhouse)
        install_winget_if_missing "ClickHouse.ClickHouse" "clickhouse"
        ;;
      mongodb)
        install_winget_if_missing "MongoDB.Server" "mongod"
        ;;
      rabbitmq)
        install_winget_if_missing "RabbitMQ.RabbitMQ" "rabbitmq-server"
        ;;
      elasticsearch)
        install_winget_if_missing "Elastic.Elasticsearch" "elasticsearch"
        ;;
      kafka)
        install_winget_if_missing "Confluent.Kafka" "kafka"
        ;;
      *)
        echo "Unknown package for Windows: $pkg"
        ;;
    esac
  done

  echo "Summary: Windows install completed for requested tools."
}

uninstall_windows() {
  local tool="$1"

  case "$tool" in
    git)
      remove_winget_if_present "Git.Git"
      ;;
    gpg)
      remove_winget_if_present "GnuPG.GnuPG"
      ;;
    curl)
      remove_winget_if_present "cURL.cURL"
      ;;
    wget)
      remove_winget_if_present "GnuWin32.Wget"
      ;;
    unzip)
      remove_winget_if_present "GnuWin32.UnZip"
      ;;
    python3)
      remove_winget_if_present "Python.Python.3.12"
      ;;
    nvm)
      remove_winget_if_present "CoreyButler.NVMforWindows"
      ;;
    node)
      remove_winget_if_present "OpenJS.NodeJS.LTS"
      ;;
    golang)
      remove_winget_if_present "GoLang.Go"
      ;;
    java)
      remove_winget_if_present "EclipseAdoptium.Temurin.25.JDK"
      ;;
    cpp)
      remove_winget_if_present "Microsoft.VisualStudio.2022.BuildTools"
      ;;
    rust)
      echo "Rustup, Rust toolchains, and Cargo data are user-managed and were left intact."
      ;;
    scala)
      remove_winget_if_present "VirtusLab.ScalaCLI"
      ;;
    r)
      remove_winget_if_present "RProject.R"
      ;;
    kubectl|kubernetes-cli)
      remove_winget_if_present "Kubernetes.kubectl"
      ;;
    helm)
      remove_winget_if_present "Helm.Helm"
      ;;
    docker)
      remove_winget_if_present "Docker.DockerDesktop"
      ;;
    dotnetcore|dotnet)
      remove_winget_if_present "Microsoft.DotNet.SDK.8"
      ;;
    vscode|code)
      remove_winget_if_present "Microsoft.VisualStudioCode"
      ;;
    gcloud|google-cloud)
      remove_winget_if_present "Google.CloudSDK"
      ;;
    aws|awscli)
      remove_winget_if_present "Amazon.AWSCLI"
      ;;
    eksctl)
      remove_winget_if_present "Weaveworks.Eksctl"
      ;;
    az|azure|azure-cli)
      remove_winget_if_present "Microsoft.AzureCLI"
      ;;
    doctl|digitalocean|doks)
      remove_winget_if_present "DigitalOcean.Doctl"
      ;;
    jq)
      remove_winget_if_present "jqlang.jq"
      ;;
    yq)
      remove_winget_if_present "MikeFarah.YQ"
      ;;
    postgres)
      remove_winget_if_present "PostgreSQL.PostgreSQL.16"
      ;;
    redis)
      remove_winget_if_present "Redis.Redis"
      ;;
    mysql)
      remove_winget_if_present "Oracle.MySQL"
      ;;
    clickhouse)
      remove_winget_if_present "ClickHouse.ClickHouse"
      ;;
    mongodb)
      remove_winget_if_present "MongoDB.Server"
      ;;
    rabbitmq)
      remove_winget_if_present "RabbitMQ.RabbitMQ"
      ;;
    elasticsearch)
      remove_winget_if_present "Elastic.Elasticsearch"
      ;;
    kafka)
      remove_winget_if_present "Confluent.Kafka"
      ;;
    *)
      echo "Unsupported Windows tool: $tool"
      ;;
  esac
}
