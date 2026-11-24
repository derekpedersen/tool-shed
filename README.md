# Tool Shed

Tool Shed is an opinionated, cross-platform bootstrap for shell helpers, developer tooling, and local service stacks on macOS, Debian-based Linux, and Windows.

The repo has three layers: shell helpers, installer/runtime control plane, and local services.

## Quick start

Root scripts are self-contained entrypoints for day-to-day operations.

| Goal | Command |
| --- | --- |
| Interactive install | curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/install.sh \| bash -s -- full |
| List | curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/list.sh \| bash -s -- |
| Preview uninstall | curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/uninstall.sh \| bash -s -- cloud --dry-run |
| Preview updates | curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/update.sh \| bash -s -- --dry-run |
| Apply updates | curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/update.sh \| bash -s -- |
| Go runtime example | curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/list.sh \| bash -s -- --runtime go --backend native cloud |

> Review remote scripts before piping to Bash. Interactive uninstall prompts for installed targets; non-interactive uninstall requires explicit targets. Preview updates before applying changes. Go-runtime wrappers auto-refresh a stale cached binary once before using legacy compatibility fallback.

Adopt existing installs before updates when needed; see [.tools/README.md](.tools/README.md).

### Go binary compatibility matrix

Use this matrix to select the correct prebuilt `tool-shed` binary for your OS/CPU.

- Published artifacts live under `.bin/tool-shed` in this repository.
- Downloaded artifacts are cached in `$HOME/.tool-shed/bin`.

| Device or environment | Typical OS / CPU | Binary artifact |
| --- | --- | --- |
| Intel Mac | macOS, x86_64 / amd64 | [tool-shed-darwin-amd64](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-darwin-amd64) |
| Apple Silicon Mac | macOS, arm64 / aarch64 | [tool-shed-darwin-arm64](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-darwin-arm64) |
| Standard Linux x64 VM/server | Linux, x86_64 / amd64 | [tool-shed-linux-amd64](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-amd64) |
| Linux ARM64 host | Linux, arm64 / aarch64 | [tool-shed-linux-arm64](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-arm64) |
| Raspberry Pi 32-bit (newer) | Linux, ARMv7 | [tool-shed-linux-armv7](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-armv7) |
| Raspberry Pi 32-bit (older) | Linux, ARMv6 | [tool-shed-linux-armv6](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-armv6) |
| Legacy Linux ARM | Linux, ARMv5 | [tool-shed-linux-armv5](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-armv5) |
| Legacy Linux x86 32-bit | Linux, i386 / i686 | [tool-shed-linux-386](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-386) |
| RISC-V Linux boards (for example BeagleV) | Linux, riscv64 | [tool-shed-linux-riscv64](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-riscv64) |
| Windows x64 | Windows, x86_64 / amd64 | [tool-shed-windows-amd64.exe](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-windows-amd64.exe) |
| Windows ARM64 | Windows, arm64 / aarch64 | [tool-shed-windows-arm64.exe](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-windows-arm64.exe) |
| Windows x86 32-bit | Windows, i386 / i686 | [tool-shed-windows-386.exe](https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-windows-386.exe) |

Classic Arduino-class microcontrollers are not supported targets for this CLI binary.

### Download and verify prebuilt binary

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-amd64 -o tool-shed
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/SHA256SUMS -o SHA256SUMS
shasum -a 256 tool-shed
grep 'tool-shed-linux-amd64' SHA256SUMS
chmod +x ./tool-shed
./tool-shed list
```

Release verification uses SHA256 checksums in `.bin/tool-shed/SHA256SUMS`.

## What is in the shed

| Domain | Location | Purpose |
| --- | --- | --- |
| Helper loft | [.bash](.bash) | Shared shell helpers and bootstrap installation for local bash workflows. |
| Tool bench | [.tools](.tools) | Bundle resolution, OS-specific installer logic, and update/uninstall orchestration. |
| Service yard | [.services](.services) | Local Docker Compose services such as PostgreSQL, Redis, RabbitMQ, MongoDB, Grafana, and Prometheus. |

Repo-root packages are modular. Each tool directory owns install/update/uninstall flow, while the shared runtime keeps behavior consistent across platforms.

## Bundles

| Bundle | Purpose |
| --- | --- |
| `full` | Default developer setup |
| `cloud` | Cloud-related tooling and helpers |
| `services` | Local services and infrastructure support |
| `ai` | AI-focused core dev tooling and package profiles |
| `software-developer` | Software engineering toolchain with cloud/devops CLIs |
| `data-science` | Analytics-oriented tooling and runtimes (no services by default) |

## Catalog

| Entry | Description |
| --- | --- |
| [aws](aws) | AWS CLI with helper workflows. |
| [az](az) | Azure CLI for resource operations. |
| [bat](bat) | Syntax-highlighted pager for files. |
| [clickhouse](clickhouse) | ClickHouse tooling for local analytics. |
| [cpp](cpp) | C/C++ compiler and build toolchain. |
| [curl](curl) | Command-line HTTP transfer utility. |
| [direnv](direnv) | Per-directory environment loading. |
| [docker](docker) | Docker CLI and container helpers. |
| [doctl](doctl) | DigitalOcean CLI operations. |
| [dotnetcore](dotnetcore) | .NET SDK/runtime tooling. |
| [eksctl](eksctl) | EKS cluster lifecycle CLI. |
| [elasticsearch](elasticsearch) | Elasticsearch local development tooling. |
| [eza](eza) | Modern replacement for `ls`. |
| [fd](fd) | Fast file finder. |
| [fzf](fzf) | Fuzzy finder for shell workflows. |
| [gcloud](gcloud) | Google Cloud SDK CLI tooling. |
| [gh](gh) | GitHub CLI automation. |
| [git](git) | Git CLI plus workflow helpers. |
| [git-config](git-config) | Git identity configuration. |
| [git-signing](git-signing) | Git commit/tag signing configuration. |
| [golang](golang) | Go toolchain and package workflow support. |
| [gpg](gpg) | GPG encryption and signing tooling. |
| [helm](helm) | Kubernetes chart/package manager. |
| [httpie](httpie) | Human-friendly HTTP client. |
| [identity](identity) | Combined Git/GPG/SSH identity setup. |
| [java](java) | Java runtime and toolchain. |
| [jq](jq) | JSON query and transform processor. |
| [julia](julia) | Julia language tooling. |
| [k9s](k9s) | Terminal UI for Kubernetes. |
| [kafka](kafka) | Kafka local development tooling. |
| [kind](kind) | Local Kubernetes-in-Docker clusters. |
| [kubectl](kubectl) | Kubernetes cluster CLI. |
| [kubeseal](kubeseal) | Sealed Secrets CLI. |
| [mongodb](mongodb) | MongoDB local development tooling. |
| [mysql](mysql) | MySQL client/server tooling. |
| [node](node) | Node.js runtime and package tooling. |
| [nvm](nvm) | Node Version Manager. |
| [postgres](postgres) | PostgreSQL local development tooling. |
| [python3](python3) | Python runtime and package tooling. |
| [r](r) | R runtime and data tooling. |
| [rabbitmq](rabbitmq) | RabbitMQ local message-broker tooling. |
| [redis](redis) | Redis local cache/queue tooling. |
| [rg](rg) | Fast recursive text search (`ripgrep`). |
| [rust](rust) | Rust toolchain. |
| [scala](scala) | Scala language tooling. |
| [ssh-key](ssh-key) | SSH key generation and setup. |
| [stern](stern) | Multi-pod Kubernetes log tailing. |
| [terraform](terraform) | Infrastructure-as-code CLI. |
| [tflint](tflint) | Terraform linting and policy checks. |
| [trivy](trivy) | Vulnerability and configuration scanner. |
| [unzip](unzip) | ZIP archive extraction utility. |
| [vscode](vscode) | Visual Studio Code tooling/integration. |
| [wget](wget) | Non-interactive download utility. |
| [yq](yq) | YAML query and transform processor. |


