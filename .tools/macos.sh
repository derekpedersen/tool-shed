#!/usr/bin/env bash
set -euo pipefail

install_brew_formula_if_missing() {
  local formula_name="$1"
  local binary_name="${2:-$formula_name}"

  if brew list --versions "$formula_name" >/dev/null 2>&1; then
    BREW_SKIPPED_COUNT=$((BREW_SKIPPED_COUNT + 1))
    return 0
  fi

  if command -v "$binary_name" >/dev/null 2>&1; then
    BREW_SKIPPED_COUNT=$((BREW_SKIPPED_COUNT + 1))
    return 0
  fi

  brew install "$formula_name"
}

install_brew_cask_if_missing() {
  local cask_name="$1"
  local app_path="${2:-}"

  if brew list --cask --versions "$cask_name" >/dev/null 2>&1; then
    BREW_SKIPPED_COUNT=$((BREW_SKIPPED_COUNT + 1))
    return 0
  fi

  if [[ -n "$app_path" ]] && [[ -e "$app_path" ]]; then
    BREW_SKIPPED_COUNT=$((BREW_SKIPPED_COUNT + 1))
    return 0
  fi

  brew install --cask "$cask_name"
}

install_mac() {
  BREW_SKIPPED_COUNT=0
  echo "Detected macOS"

  if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$('/opt/homebrew/bin/brew shellenv')"
    elif [[ -f /usr/local/bin/brew ]]; then
      eval "$('/usr/local/bin/brew shellenv')"
    fi
  fi

  for pkg in "$@"; do
    case "$pkg" in
      git)
        install_brew_formula_if_missing "git"
        install_brew_formula_if_missing "bash-completion"
        install_brew_formula_if_missing "vim"
        configure_git_editor
        configure_git_completion
        ;;
      gpg)
        install_brew_formula_if_missing "gnupg"
        ;;
      helm)
        install_brew_formula_if_missing "helm"
        configure_helm_completion
        ;;
      kubectl)
        install_brew_formula_if_missing "kubectl"
        configure_kubectl_completion
        ;;
      kubernetes-cli)
        install_brew_formula_if_missing "kubectl"
        configure_kubectl_completion
        ;;
      docker)
        echo "Docker Desktop is typically installed via the official app, not Homebrew."
        echo "Install it from: https://www.docker.com/products/docker-desktop/"
        configure_docker_completion
        ;;
      gcloud|google-cloud)
        install_brew_cask_if_missing "google-cloud-sdk"
        configure_gcloud_completion
        ;;
      aws|awscli)
        install_brew_formula_if_missing "awscli" "aws"
        configure_aws_completion
        ;;
      eksctl)
        install_brew_formula_if_missing "eksctl"
        ;;
      az|azure|azure-cli)
        install_brew_formula_if_missing "azure-cli" "az"
        configure_az_completion
        ;;
      doctl|digitalocean|doks)
        install_brew_formula_if_missing "doctl"
        configure_doctl_completion
        ;;
      golang)
        install_brew_formula_if_missing "go"
        export PATH="$PATH:/usr/local/go/bin:/opt/homebrew/bin:$HOME/go/bin"
        install_go_dev_packages "go"
        ;;
      java)
        install_brew_cask_if_missing "temurin@25"
        ;;
      nvm)
        echo "Installing nvm..."
        if ! [ -d "$HOME/.nvm" ]; then
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        fi
        export NVM_DIR="$HOME/.nvm"
        if [ -s "$NVM_DIR/nvm.sh" ]; then
          # nvm.sh exits non-zero under set -eu
          set +eu
          . "$NVM_DIR/nvm.sh"
          if ! command -v node >/dev/null 2>&1; then
            nvm install --lts
          fi
          nvm alias default lts/* >/dev/null 2>&1 || true
          set -eu
        fi
        ;;
      node)
        echo "Installing Node LTS via nvm..."
        export NVM_DIR="$HOME/.nvm"
        if ! [ -s "$NVM_DIR/nvm.sh" ]; then
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        fi
        if [ -s "$NVM_DIR/nvm.sh" ]; then
          # nvm.sh exits non-zero under set -eu
          set +eu
          . "$NVM_DIR/nvm.sh"
          if ! command -v node >/dev/null 2>&1; then
            nvm install --lts
          fi
          nvm alias default lts/* >/dev/null 2>&1 || true
          export PATH="$PATH:$HOME/.nvm/versions/node/$(nvm version default 2>/dev/null || echo "$(nvm ls --no-colors default 2>/dev/null | tail -n 1 | awk '{print $1}' | tr -d 'v')")/bin"
          set -eu
        fi
        install_node_dev_packages "node"
        ;;
      dotnetcore)
        install_brew_cask_if_missing "dotnet-sdk"
        ;;
      dotnet)
        install_brew_cask_if_missing "dotnet-sdk"
        ;;
      vscode|code)
        install_brew_cask_if_missing "visual-studio-code" "/Applications/Visual Studio Code.app"
        ;;
      curl)
        echo "curl is already included with macOS."
        ;;
      unzip)
        install_brew_formula_if_missing "unzip"
        ;;
      wget)
        install_brew_formula_if_missing "wget"
        ;;
      python3)
        install_brew_formula_if_missing "python"
        install_python_dev_packages "python3"
        ;;
      postgres)
        install_brew_formula_if_missing "postgresql@16"
        echo "Postgres installed. Start it with: brew services start postgresql@16"
        ;;
      redis)
        install_brew_formula_if_missing "redis"
        echo "Redis installed. Start it with: brew services start redis"
        ;;
      mysql)
        install_brew_formula_if_missing "mysql"
        echo "MySQL installed. Start it with: brew services start mysql"
        ;;
      clickhouse)
        install_brew_formula_if_missing "clickhouse"
        echo "ClickHouse installed. Start it with: clickhouse local or brew services start clickhouse"
        ;;
      mongodb)
        install_brew_formula_if_missing "mongodb-community"
        echo "MongoDB installed. Start it with: brew services start mongodb-community"
        ;;
      rabbitmq)
        install_brew_formula_if_missing "rabbitmq"
        echo "RabbitMQ installed. Start it with: brew services start rabbitmq"
        ;;
      elasticsearch)
        install_brew_formula_if_missing "elasticsearch"
        echo "Elasticsearch installed. Start it with: brew services start elasticsearch"
        ;;
      kafka)
        install_brew_formula_if_missing "kafka"
        echo "Kafka installed. Start it with: brew services start kafka"
        ;;
      *)
        echo "Unknown package for macOS: $pkg"
        ;;
    esac
  done

  if (( BREW_SKIPPED_COUNT > 0 )); then
    echo "Summary: $BREW_SKIPPED_COUNT package(s) were already installed; no reinstall attempted."
  else
    echo "Summary: all requested packages were installed or configured."
  fi
}
