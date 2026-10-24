#!/usr/bin/env bash
set -euo pipefail

install_apt_pkg_if_missing() {
  local pkg="$1"
  local binary_name="${2:-$1}"

  if command -v "$binary_name" >/dev/null 2>&1 || dpkg -s "$pkg" >/dev/null 2>&1; then
    LINUX_SKIPPED_COUNT=$((LINUX_SKIPPED_COUNT + 1))
    return 0
  fi

  if [[ -n "${SUDO:-}" ]]; then
    $SUDO apt-get install -y "$pkg"
  else
    apt-get install -y "$pkg"
  fi
}

linux_ubuntu_codename() {
  printf '%s\n' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
}

install_linux() {
  LINUX_SKIPPED_COUNT=0
  echo "Detected Linux"

  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
  fi

  IS_DEBIAN_BASED=false
  if [[ "${ID:-}" == "ubuntu" || "${ID:-}" == "debian" || "${ID:-}" == "linuxmint" || "${ID_LIKE:-}" == *"debian"* ]]; then
    IS_DEBIAN_BASED=true
  fi

  if ! $IS_DEBIAN_BASED; then
    echo "This installer currently supports Debian-based Linux distros only: Ubuntu, Debian, Linux Mint."
    exit 1
  fi

  export DEBIAN_FRONTEND=noninteractive
  sudo -n true >/dev/null 2>&1 || echo "sudo not available or no password; continuing if already root."

  if command -v sudo >/dev/null 2>&1; then
    # sudo resets the environment, so pass noninteractive explicitly to avoid hung debconf prompts
    SUDO="sudo env DEBIAN_FRONTEND=noninteractive"
  else
    SUDO=""
  fi

  # MongoDB 7.0 only publishes focal/jammy; a stale 7.0 source 404s and breaks apt-get update.
  local legacy_mongodb_repo="/etc/apt/sources.list.d/mongodb-org-7.0.list"
  if [[ -f "$legacy_mongodb_repo" ]] && ! grep -Eq "repo.mongodb.org/apt/ubuntu (focal|jammy)/" "$legacy_mongodb_repo"; then
    echo "Removing unsupported MongoDB 7.0 apt source: $legacy_mongodb_repo"
    $SUDO rm -f "$legacy_mongodb_repo"
  fi

  if [[ -n "${SUDO}" ]]; then
    $SUDO apt-get update
  else
    apt-get update
  fi

  for pkg in "$@"; do
    case "$pkg" in
      git)
        install_apt_pkg_if_missing "git" "git"
        install_apt_pkg_if_missing "bash-completion" "bash"
        install_apt_pkg_if_missing "vim" "vim"
        configure_git_editor
        configure_git_completion
        ;;
      gpg)
        install_apt_pkg_if_missing "gnupg" "gpg"
        ;;
      helm)
        install_apt_pkg_if_missing "curl" "curl"
        install_apt_pkg_if_missing "apt-transport-https" "apt"
        install_apt_pkg_if_missing "gnupg" "gpg"
        if ! command -v helm >/dev/null 2>&1; then
          curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        fi
        configure_helm_completion
        ;;
      kubectl)
        install_apt_pkg_if_missing "curl" "curl"
        if ! command -v kubectl >/dev/null 2>&1; then
          curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x /usr/local/bin/kubectl
        fi
        configure_kubectl_completion
        ;;
      kubernetes-cli)
        install_apt_pkg_if_missing "curl" "curl"
        if ! command -v kubectl >/dev/null 2>&1; then
          curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x /usr/local/bin/kubectl
        fi
        configure_kubectl_completion
        ;;
      golang)
        install_apt_pkg_if_missing "wget" "wget"
        install_apt_pkg_if_missing "tar" "tar"
        if ! command -v go >/dev/null 2>&1; then
          GO_VERSION="1.22.7"
          cd /tmp
          wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
          rm -rf /usr/local/go
          tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
          echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
        fi
        export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
        install_go_dev_packages "go"
        ;;
      java)
        local adoptium_codename
        adoptium_codename="$(linux_ubuntu_codename)"
        if [[ -z "$adoptium_codename" ]]; then
          echo "Unable to determine the Debian or Ubuntu release codename for the Adoptium repository." >&2
          return 1
        fi

        install_apt_pkg_if_missing "ca-certificates" "ca-certificates"
        install_apt_pkg_if_missing "curl" "curl"
        install_apt_pkg_if_missing "gpg" "gpg"
        if [[ ! -f /etc/apt/keyrings/adoptium.gpg ]]; then
          $SUDO install -m 0755 -d /etc/apt/keyrings
          curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/adoptium.gpg
        fi
        $SUDO chmod a+r /etc/apt/keyrings/adoptium.gpg
        printf 'deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb %s main\n' "$adoptium_codename" | $SUDO tee /etc/apt/sources.list.d/adoptium.list >/dev/null
        if [[ -n "${SUDO:-}" ]]; then
          $SUDO apt-get update
        else
          apt-get update
        fi
        install_apt_pkg_if_missing "temurin-25-jdk" "temurin-25-jdk"
        ;;
      cpp)
        install_apt_pkg_if_missing "build-essential" "build-essential"
        ;;
      rust)
        install_apt_pkg_if_missing "curl" "curl"
        install_rustup_if_missing
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
          nvm install --lts
          nvm use --lts
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
          nvm install --lts
          nvm use --lts
          nvm alias default lts/* >/dev/null 2>&1 || true
          export PATH="$PATH:$HOME/.nvm/versions/node/$(nvm version default 2>/dev/null || echo "$(nvm ls --no-colors default 2>/dev/null | tail -n 1 | awk '{print $1}' | tr -d 'v')")/bin"
          set -eu
        fi
        install_node_dev_packages "node"
        ;;
      dotnetcore)
        install_apt_pkg_if_missing "wget" "wget"
        install_apt_pkg_if_missing "gpg" "gpg"
        install_apt_pkg_if_missing "apt-transport-https" "apt"
        if ! command -v dotnet >/dev/null 2>&1; then
          wget https://packages.microsoft.com/config/ubuntu/$(. /etc/os-release; echo "$VERSION_ID")/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
          if [[ -n "${SUDO:-}" ]]; then
            $SUDO dpkg -i /tmp/packages-microsoft-prod.deb
            $SUDO apt-get update
            $SUDO apt-get install -y dotnet-sdk-8.0
          else
            dpkg -i /tmp/packages-microsoft-prod.deb
            apt-get update
            apt-get install -y dotnet-sdk-8.0
          fi
        fi
        ;;
      dotnet)
        install_apt_pkg_if_missing "wget" "wget"
        install_apt_pkg_if_missing "gpg" "gpg"
        install_apt_pkg_if_missing "apt-transport-https" "apt"
        if ! command -v dotnet >/dev/null 2>&1; then
          wget https://packages.microsoft.com/config/ubuntu/$(. /etc/os-release; echo "$VERSION_ID")/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
          if [[ -n "${SUDO:-}" ]]; then
            $SUDO dpkg -i /tmp/packages-microsoft-prod.deb
            $SUDO apt-get update
            $SUDO apt-get install -y dotnet-sdk-8.0
          else
            dpkg -i /tmp/packages-microsoft-prod.deb
            apt-get update
            apt-get install -y dotnet-sdk-8.0
          fi
        fi
        ;;
      vscode|code)
        if ! command -v code >/dev/null 2>&1; then
          wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
          $SUDO install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
          $SUDO sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
          $SUDO apt-get update
          $SUDO apt-get install -y code
        fi
        ;;
      docker)
        install_apt_pkg_if_missing "ca-certificates" "ca-certificates"
        install_apt_pkg_if_missing "curl" "curl"
        install_apt_pkg_if_missing "gnupg" "gpg"
        install_apt_pkg_if_missing "lsb-release" "lsb_release"
        if ! command -v docker >/dev/null 2>&1; then
          if [[ -n "${SUDO}" ]]; then
            $SUDO install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
            $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
          else
            echo "docker install requires sudo."
          fi
        fi
        configure_docker_completion
        ;;
      gcloud|google-cloud)
        if ! command -v gcloud >/dev/null 2>&1; then
          install_apt_pkg_if_missing "apt-transport-https" "apt"
          install_apt_pkg_if_missing "ca-certificates" "ca-certificates"
          install_apt_pkg_if_missing "gnupg" "gpg"
          install_apt_pkg_if_missing "curl" "curl"
          curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
          echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | $SUDO tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
          $SUDO apt-get update
          $SUDO apt-get install -y google-cloud-cli
        fi
        configure_gcloud_completion
        ;;
      aws|awscli)
        if ! command -v aws >/dev/null 2>&1; then
          install_apt_pkg_if_missing "unzip" "unzip"
          install_apt_pkg_if_missing "curl" "curl"
          local aws_arch
          case "$(dpkg --print-architecture)" in
            amd64) aws_arch="x86_64" ;;
            arm64) aws_arch="aarch64" ;;
            *) echo "Unsupported AWS CLI architecture: $(dpkg --print-architecture)" >&2; return 1 ;;
          esac
          curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o /tmp/awscliv2.zip
          mkdir -p /tmp/awscli-installer
          unzip -q -o /tmp/awscliv2.zip -d /tmp/awscli-installer
          $SUDO /tmp/awscli-installer/aws/install --update
        fi
        configure_aws_completion
        ;;
      eksctl)
        if ! command -v eksctl >/dev/null 2>&1; then
          curl -fsSL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o /tmp/eksctl.tar.gz
          tar -xzf /tmp/eksctl.tar.gz -C /tmp
          $SUDO install /tmp/eksctl /usr/local/bin/eksctl
        fi
        ;;
      az|azure|azure-cli)
        if ! command -v az >/dev/null 2>&1; then
          curl -sL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
        fi
        configure_az_completion
        ;;
      doctl|digitalocean|doks)
        if ! command -v doctl >/dev/null 2>&1; then
          curl -fsSL -o /tmp/doctl.tar.gz https://github.com/digitalocean/doctl/releases/download/v1.110.0/doctl-1.110.0-linux-amd64.tar.gz
          tar -xzf /tmp/doctl.tar.gz -C /tmp
          $SUDO install /tmp/doctl /usr/local/bin/doctl
        fi
        configure_doctl_completion
        ;;
      curl)
        install_apt_pkg_if_missing "curl" "curl"
        ;;
      unzip)
        install_apt_pkg_if_missing "unzip" "unzip"
        ;;
      wget)
        install_apt_pkg_if_missing "wget" "wget"
        ;;
      python3)
        install_apt_pkg_if_missing "python3" "python3"
        install_apt_pkg_if_missing "python3-pip" "pip3"
        install_apt_pkg_if_missing "python3-venv" "python3-venv"
        install_python_dev_packages "python3"
        ;;
      jq)
        install_apt_pkg_if_missing "jq" "jq"
        ;;
      yq)
        local yq_arch
        case "$(uname -m)" in
          x86_64) yq_arch="amd64" ;;
          aarch64) yq_arch="arm64" ;;
          armv7l) yq_arch="arm" ;;
          *) echo "Unsupported yq architecture: $(uname -m)" >&2; return 1 ;;
        esac
        if ! command -v yq >/dev/null 2>&1; then
          curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${yq_arch}" -o /tmp/yq
          $SUDO install -m 0755 /tmp/yq /usr/local/bin/yq
        fi
        ;;
      postgres)
        install_apt_pkg_if_missing "postgresql" "pg_ctl"
        install_apt_pkg_if_missing "postgresql-contrib" "psql"
        if command -v pg_ctl >/dev/null 2>&1; then
          echo "Postgres installed. Start it with: sudo service postgresql start"
        fi
        ;;
      redis)
        install_apt_pkg_if_missing "redis-server" "redis-server"
        if command -v redis-server >/dev/null 2>&1; then
          echo "Redis installed. Start it with: sudo service redis-server start"
        fi
        ;;
      mysql)
        install_apt_pkg_if_missing "mysql-server" "mysqld"
        if command -v mysqld >/dev/null 2>&1; then
          echo "MySQL installed. Start it with: sudo service mysql start"
        fi
        ;;
      clickhouse)
        install_apt_pkg_if_missing "apt-transport-https" "apt"
        install_apt_pkg_if_missing "ca-certificates" "ca-certificates"
        install_apt_pkg_if_missing "gnupg" "gpg"
        if ! command -v clickhouse-server >/dev/null 2>&1; then
          echo "Installing ClickHouse packages."
          echo "If prompted for the default user password, input is hidden."
          echo "Press Enter to keep an empty password, then press Enter again to confirm."
          echo "deb [arch=$(dpkg --print-architecture)] https://packages.clickhouse.com/deb stable main" | $SUDO tee /etc/apt/sources.list.d/clickhouse.list >/dev/null
          curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor | $SUDO tee /etc/apt/trusted.gpg.d/clickhouse.gpg >/dev/null
          $SUDO apt-get update
          $SUDO apt-get install -y clickhouse-server clickhouse-client
        fi
        echo "ClickHouse installed. Start it with: sudo service clickhouse-server start"
        ;;
      mongodb)
        install_apt_pkg_if_missing "gnupg" "gpg"
        install_apt_pkg_if_missing "curl" "curl"
        if ! command -v mongod >/dev/null 2>&1; then
          curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg
          echo "deb [ arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(linux_ubuntu_codename)/mongodb-org/8.0 multiverse" | $SUDO tee /etc/apt/sources.list.d/mongodb-org-8.0.list >/dev/null
          $SUDO apt-get update
          $SUDO apt-get install -y mongodb-org
        fi
        echo "MongoDB installed. Start it with: sudo systemctl start mongod"
        ;;
      rabbitmq)
        install_apt_pkg_if_missing "curl" "curl"
        install_apt_pkg_if_missing "gnupg" "gpg"
        if ! command -v rabbitmq-server >/dev/null 2>&1; then
          local rabbitmq_arch rabbitmq_codename
          rabbitmq_arch="$(dpkg --print-architecture)"
          rabbitmq_codename="$(linux_ubuntu_codename)"
          curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/rabbitmq.gpg
          if [[ "$rabbitmq_arch" == "amd64" ]]; then
            {
              printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.gpg] https://deb1.rabbitmq.com/rabbitmq-erlang/ubuntu/%s %s main\n' "$rabbitmq_codename" "$rabbitmq_codename"
              printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.gpg] https://deb2.rabbitmq.com/rabbitmq-erlang/ubuntu/%s %s main\n' "$rabbitmq_codename" "$rabbitmq_codename"
              printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.gpg] https://deb1.rabbitmq.com/rabbitmq-server/ubuntu/%s %s main\n' "$rabbitmq_codename" "$rabbitmq_codename"
              printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.gpg] https://deb2.rabbitmq.com/rabbitmq-server/ubuntu/%s %s main\n' "$rabbitmq_codename" "$rabbitmq_codename"
            } | $SUDO tee /etc/apt/sources.list.d/rabbitmq.list >/dev/null
          elif [[ "$rabbitmq_arch" == "arm64" ]]; then
            curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf77f1eda57ebb1cc' | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/rabbitmq-erlang.gpg
            {
              printf 'deb [arch=arm64 signed-by=/usr/share/keyrings/rabbitmq-erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu %s main\n' "$rabbitmq_codename"
              printf 'deb [arch=arm64 signed-by=/usr/share/keyrings/rabbitmq.gpg] https://deb1.rabbitmq.com/rabbitmq-server/ubuntu/%s %s main\n' "$rabbitmq_codename" "$rabbitmq_codename"
              printf 'deb [arch=arm64 signed-by=/usr/share/keyrings/rabbitmq.gpg] https://deb2.rabbitmq.com/rabbitmq-server/ubuntu/%s %s main\n' "$rabbitmq_codename" "$rabbitmq_codename"
            } | $SUDO tee /etc/apt/sources.list.d/rabbitmq.list >/dev/null
          else
            echo "Unsupported RabbitMQ architecture: $rabbitmq_arch" >&2
            return 1
          fi
          $SUDO apt-get update
          $SUDO apt-get install -y rabbitmq-server
        fi
        echo "RabbitMQ installed. Start it with: sudo systemctl start rabbitmq-server"
        ;;
      elasticsearch)
        install_apt_pkg_if_missing "gnupg" "gpg"
        install_apt_pkg_if_missing "curl" "curl"
        if ! command -v elasticsearch >/dev/null 2>&1; then
          wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/elasticsearch-keyring.gpg
          echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | $SUDO tee /etc/apt/sources.list.d/elastic-8.x.list >/dev/null
          $SUDO apt-get update
          $SUDO apt-get install -y elasticsearch
        fi
        echo "Elasticsearch installed. Start it with: sudo systemctl start elasticsearch"
        ;;
      kafka)
        install_apt_pkg_if_missing "curl" "curl"
        install_apt_pkg_if_missing "ca-certificates" "ca-certificates"
        if ! command -v kafka-server-start >/dev/null 2>&1; then
          $SUDO apt-get install -y openjdk-17-jre-headless
          curl -fsSL https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz -o /tmp/kafka.tgz
          $SUDO install -d /opt/kafka
          $SUDO tar -xzf /tmp/kafka.tgz -C /opt/kafka --strip-components=1
          echo "Kafka downloaded to /opt/kafka. Start it with: /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties"
        fi
        ;;
      *)
        echo "Unknown package for Linux: $pkg"
        ;;
    esac
  done

  if (( LINUX_SKIPPED_COUNT > 0 )); then
    echo "Summary: $LINUX_SKIPPED_COUNT package(s) were already installed; no reinstall attempted."
  else
    echo "Summary: all requested packages were installed or configured."
  fi
}
