# Tool Shed

Curated shell helpers, bootstrap installers, and small operational tooling for local development.

Think of this repo as a well-labeled shed: the helper loft holds shell shortcuts, the tool bench runs installs and uninstalls, and the service yard keeps local dependencies ready when you need them.

## What’s in the shed

- [.bash/README.md](.bash/README.md) for shell helper usage and the helper loft
- [.tools/README.md](.tools/README.md) for the installer/runtime layer and the tool bench
- [.services](.services) for isolated local Docker Compose service stacks in the service yard
- [Makefile](Makefile) for shared build/test orchestration
- [Jenkinsfile](Jenkinsfile) for CI entry points that call the shared Makefile targets

This repo intentionally separates concerns into three zones:

| Domain | Location | Purpose |
| --- | --- | --- |
| Helper loft | [.bash](.bash) | Shell bootstrap, helper installation, and shared bash snippets used across tool modules. |
| Tool bench | [.tools](.tools) | Bundle orchestration, install/uninstall controllers, OS-specific logic, and shared runtime behavior. |
| Service yard | [.services](.services) | Docker Compose-based local dev services such as PostgreSQL, Redis, RabbitMQ, MongoDB, Grafana, and Prometheus. |

The repo-root tool folders are intentionally atomized and individual. Each package such as [docker](docker), [kubectl](kubectl), [aws](aws), [gcloud](gcloud), and [git](git) has its own hook on the wall: install, uninstall, and any optional bash helpers or Windows shims.

## Shed catalog

| Folder | Abbrev. | Full name | What it is | Link |
| --- | --- | --- | --- | --- |
| [.bash](.bash) | Bash | Bash helper loft | Shell helper install/uninstall flow and shared bash snippets for local workflows. | [.bash/README.md](.bash/README.md) |
| [.github](.github) | GitHub | GitHub repo config | Repository automation, automation rules, and GitHub-specific guidance for contributors and Copilot. | [GitHub Docs](https://docs.github.com/) |
| [.services](.services) | SVC | Local service yard | Docker Compose stack for PostgreSQL, Redis, RabbitMQ, MongoDB, and observability containers. | [.services/README.md](.services/README.md) |
| [.tools](.tools) | Tools | Tool bench runtime | Bundle-based installer, OS-specific logic, and shared runtime for developer tooling. | [.tools/README.md](.tools/README.md) |
| [aws](aws) | AWS | Amazon Web Services CLI | AWS CLI and AWS-specific helper scripts. | [AWS CLI](https://aws.amazon.com/cli/) |
| [az](az) | Azure | Azure CLI | Microsoft Azure command-line tooling and convenience helpers. | [Azure CLI](https://learn.microsoft.com/cli/azure/) |
| [clickhouse](clickhouse) | CH | ClickHouse | ClickHouse database installer and setup helpers. | [ClickHouse](https://clickhouse.com/) |
| [cloud](cloud) | Cloud | Multi-cloud helpers | Shared cloud-oriented bash helpers for multi-cloud status and context checks. | [Cloud computing](https://en.wikipedia.org/wiki/Cloud_computing) |
| [cpp](cpp) | C/C++ | Native C/C++ toolchains | Platform-native compilers for Debian-based Linux, macOS, and Windows. | [C++](https://isocpp.org/) |
| [curl](curl) | Curl | cURL | HTTP client for transfers from the shell. | [curl](https://curl.se/) |
| [docker](docker) | Docker | Docker | Docker CLI helpers and container workflow support. | [Docker](https://www.docker.com/) |
| [doctl](doctl) | DOCTL | DigitalOcean CLI | DigitalOcean command-line interface and convenience commands. | [doctl](https://docs.digitalocean.com/reference/doctl/) |
| [dotnetcore](dotnetcore) | .NET | .NET SDK | .NET runtime and SDK bootstrap helpers. | [.NET](https://dotnet.microsoft.com/) |
| [eksctl](eksctl) | EKSCTL | Amazon EKS CLI | CLI for creating and managing Amazon EKS clusters. | [eksctl](https://eksctl.io/) |
| [elasticsearch](elasticsearch) | ES | Elasticsearch | Elasticsearch install and operational helpers. | [Elasticsearch](https://www.elastic.co/elasticsearch/) |
| [gcloud](gcloud) | GCP | Google Cloud SDK | Google Cloud CLI and helpers for GCP developer workflows. | [Google Cloud SDK](https://cloud.google.com/sdk) |
| [git](git) | Git | Git | Git aliases, workflow helpers, and repo automation commands. | [Git](https://git-scm.com/) |
| [git-config](git-config) | GitCfg | Git config setup | Idempotent Git identity and configuration bootstrap. | [Git configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration) |
| [git-signing](git-signing) | GitSig | Git signing setup | GPG-based signing setup for Git commit and tag verification. | [Signing commits](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work) |
| [golang](golang) | Go | Go toolchain | Go language install and environment bootstrap. | [Go](https://go.dev/) |
| [gpg](gpg) | GPG | GNU Privacy Guard | GPG key generation and signing setup. | [GnuPG](https://gnupg.org/) |
| [helm](helm) | Helm | Helm package manager | Helm chart helpers, release shortcuts, and version stamping tools. | [Helm](https://helm.sh/) |
| [identity](identity) | ID | Identity setup | Combined identity/bootstrap helpers for Git, SSH, and GPG setup. | [Identity management](https://en.wikipedia.org/wiki/Identity_management) |
| [java](java) | Java | Eclipse Temurin JDK 25 | Java 25 developer toolchain with the Java runtime and compiler. | [Eclipse Temurin](https://adoptium.net/) |
| [julia](julia) | Julia | Juliaup-managed Julia | Stable Julia runtime and version manager; existing user channels and packages are preserved on uninstall. | [Julia](https://julialang.org/) |
| [jq](jq) | jq | jq JSON processor | Lightweight JSON parsing and filtering from the shell. | [jq](https://jqlang.github.io/jq/) |
| [kafka](kafka) | Kafka | Apache Kafka | Kafka broker install and local data platform helpers. | [Kafka](https://kafka.apache.org/) |
| [kubectl](kubectl) | kubectl | Kubernetes CLI | Kubernetes administration and cluster troubleshooting helpers. | [kubectl](https://kubernetes.io/docs/reference/kubectl/) |
| [mongodb](mongodb) | MongoDB | MongoDB | MongoDB database metadata and local developer setup. | [MongoDB](https://www.mongodb.com/) |
| [mysql](mysql) | MySQL | MySQL | MySQL database install and config workflow for local apps. | [MySQL](https://www.mysql.com/) |
| [node](node) | Node | Node.js | Node.js runtime and package-manager bootstrap helpers. | [Node.js](https://nodejs.org/) |
| [nvm](nvm) | NVM | Node Version Manager | Node version switching and environment management. | [nvm](https://github.com/nvm-sh/nvm) |
| [postgres](postgres) | PG | PostgreSQL | PostgreSQL database install and local stack support. | [PostgreSQL](https://www.postgresql.org/) |
| [python3](python3) | Py3 | Python 3 | Python 3 runtime setup and related developer helpers. | [Python](https://www.python.org/) |
| [r](r) | R | R interpreter | Statistical computing and graphics runtime; CRAN packages remain project-managed. | [R Project](https://www.r-project.org/) |
| [rabbitmq](rabbitmq) | RabbitMQ | RabbitMQ | AMQP broker install and local messaging toolkit support. | [RabbitMQ](https://www.rabbitmq.com/) |
| [redis](redis) | Redis | Redis | In-memory data store and cache setup for local apps. | [Redis](https://redis.io/) |
| [rust](rust) | Rust | Rust stable toolchain | Per-user stable Rust toolchain managed by rustup. | [Rust](https://www.rust-lang.org/) |
| [scala](scala) | Scala | Scala CLI | Scala 3 REPL, compiler, runner, and package tool. | [Scala](https://www.scala-lang.org/) |
| [ssh-key](ssh-key) | SSH | SSH key bootstrap | SSH key generation and installation for remote auth. | [OpenSSH](https://www.openssh.com/) |
| [unzip](unzip) | Unzip | Unzip utility | Zip extraction helper and wrappers for local tooling. | [Info-ZIP UnZip](https://www.info-zip.org/UnZip.html) |
| [vscode](vscode) | VS Code | Visual Studio Code | Editor bootstrap and local environment setup for VS Code. | [VS Code](https://code.visualstudio.com/) |
| [wget](wget) | Wget | GNU Wget | Command-line downloader for HTTP and HTTPS fetches. | [GNU Wget](https://www.gnu.org/software/wget/) |
| [yq](yq) | yq | yq YAML processor | YAML processing and transformation helpers. | [yq](https://mikefarah.gitbook.io/yq/) |

## Service yard

- [.services/docker-compose.yml](.services/docker-compose.yml): isolated local stack for PostgreSQL, Redis, RabbitMQ, MongoDB, and optional observability services
- [.services/local-dev.sh](.services/local-dev.sh): interactive preset-based launcher for starting and stopping the local stack
- [.services/grafana](.services/grafana): Grafana provisioning config for the local observability stack
- [.services/prometheus](.services/prometheus): Prometheus config for the local observability stack
- [.services/README.md](.services/README.md): stack usage notes and port references

### Signage and guidance

- [AGENTS.md](AGENTS.md): repository agent guidance
- [.github/copilot-instructions.md](.github/copilot-instructions.md): Copilot-specific conventions
- [.github/dependabot.yml](.github/dependabot.yml): weekly dependency update checks for GitHub Actions, Docker, and Python packages

## Quick start

### Use the root installer prompt

From this repo:

```bash
./install.sh
```

One-liner from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/install.sh | bash
```

This interactive wrapper asks whether to run bash helper install and tools install, then delegates to the existing installers.

### Open the helper loft

From this repo:

```bash
bash ./.bash/install.sh
```

One-liner from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bash/install.sh | bash
```

The installer gathers the selected helper files into a single managed file (`~/.tool-shed-bash-helpers`) and sources it from your shell profile. The profile only references that stable file, so the helpers keep working even if the repo clone or bootstrap temp directory is removed. Rerun the installer whenever you want to restock the shelf.

Optional overrides for testing another branch or fork, or changing the managed helpers file:

```bash
TOOL_SHED_REF=feature/my-branch TOOL_SHED_REPO=derekpedersen/tool-shed curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bash/install.sh | bash
TOOL_SHED_HELPERS_FILE=~/.my-helpers curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bash/install.sh | bash
```

### Load the tool bench

From this repo:

```bash
bash ./.tools/install.sh full
```

Native Windows 11+ support is included. Use either Git Bash/MSYS, PowerShell with the bundled wrapper, or WSL/Linux paths as appropriate:

```powershell
pwsh ./.tools/install.ps1 full
```

```bash
bash ./.tools/install.sh full
```

One-liner from GitHub (replace full with ai or cloud):

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.tools/install.sh | bash -s -- full
```

Optional override for testing another branch or fork during bootstrap:

```bash
TOOL_SHED_REF=feature/my-branch TOOL_SHED_REPO=derekpedersen/tool-shed curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.tools/install.sh | bash -s -- full
```

Install output is also written to `~/.tool-shed/logs/install-<timestamp>.log` (override with `TOOL_SHED_LOG_DIR`). Dry runs are not logged.

### Close the doors

```bash
bash ./.bash/uninstall.sh
```

This removes the managed source block from your shell profile and deletes the generated helper file (`~/.tool-shed-bash-helpers`).

### Pack up the tools

```bash
bash ./.tools/uninstall.sh full
bash ./.tools/uninstall.sh services
bash ./.tools/uninstall.sh kubectl docker
bash ./.tools/uninstall.sh ai --dry-run
```

Windows examples:

```powershell
pwsh ./.tools/uninstall.ps1 full
pwsh ./.tools/uninstall.ps1 docker vscode --dry-run
```

The uninstall flow mirrors the install pattern: it is explicit, target-based, and safe by default.

## Tool bundles

- full (default): base developer setup + R, Scala, C/C++, and Rust toolchains + cloud CLIs + local data/service tooling
- cloud: base setup + kubernetes/docker/cloud CLIs and JSON/YAML helpers
- services: local data/service tooling only (postgres, redis, mysql, clickhouse, mongodb, rabbitmq, elasticsearch, kafka)
- ai: base setup, including R, Temurin JDK 25, Scala, C/C++, and Rust, + AI-oriented Python/Go packages and full Node package profile

For language-by-language tool selection, run the guided root installer:

```bash
./install.sh
```

Bundle quick examples:

```bash
bash ./.tools/install.sh full
bash ./.tools/install.sh cloud
bash ./.tools/install.sh services
bash ./.tools/install.sh ai
```

Dry run example:

```bash
bash ./.tools/install.sh ai --dry-run
```

Identity setup examples:

```bash
GIT_USER_NAME='Jane Doe' GIT_USER_EMAIL='jane@example.com' bash ./.tools/install.sh git-config
GIT_USER_NAME='Jane Doe' GIT_USER_EMAIL='jane@example.com' GPG_KEY_ID='ABC123DEF456' bash ./.tools/install.sh gpg git-signing
SSH_KEY_EMAIL='jane@example.com' bash ./.tools/install.sh ssh-key
bash ./.tools/install.sh identity
```

## Workshop checks


The shared CI entry points are:

- `make build` for syntax checks and Helm version stamping validation
- `make test` for installer smoke tests, including install and uninstall dry-run coverage

[Jenkinsfile](Jenkinsfile) calls those same targets so local runs and CI stay aligned.

Build/test coverage includes:

- syntax of files in [.bash](.bash)
- syntax of files in [.tools](.tools)
- installer smoke tests for full, cloud, services, and ai bundles using dry-run mode
- uninstaller smoke tests for full, cloud, services, and ai bundles using dry-run mode
