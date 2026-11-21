# Tool Shed

Tool Shed is a cross-platform installer for shell helpers, developer tools, and local service stacks on macOS, Debian-based Linux, and Windows.

The repo is split into three parts: helper scripts, installer/runtime logic, and local service setup.

## Quick start

Root scripts are self-contained entrypoints. You can run any root script with a single `curl | bash` command without cloning the full repository first. If local runtime files are missing, the script bootstraps what it needs from GitHub at runtime.

### Run the root installer prompt

This is the interactive root installer. It asks whether to install bash helpers and whether to run the tools installer. Both default to yes, and the tools install defaults to the `full` bundle.

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/install.sh | bash -s -- full
```

PowerShell / Windows users can also run the bundled wrapper:

```powershell
pwsh ./.tools/install.ps1 full
```

### List installed tools and versions

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/list.sh | bash -s --
```

### Preview a bundle removal

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/uninstall.sh | bash -s -- cloud --dry-run
```

### Preview managed updates

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/update.sh | bash -s -- --dry-run
```

### Apply managed updates

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/update.sh | bash -s --
```

> Review scripts before piping remote code into Bash. Uninstall requires an explicit tool or bundle target, and updates should be previewed before real changes.

Remote runtime selection also works from one-liners:

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/list.sh | bash -s -- --runtime go --backend native cloud
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/update.sh | bash -s -- --runtime shell --dry-run cloud
```

### From a repo checkout

```bash
bash ./install.sh
bash ./list.sh
bash ./uninstall.sh cloud --dry-run
bash ./update.sh --dry-run
bash ./update.sh
```

Root scripts are runtime selectors. They prompt for runtime when `--runtime` is not set, and dispatch to either shell or Go execution paths.

Root wrappers also support explicit runtime and backend selection:

```bash
bash ./list.sh --runtime go --backend native cloud
bash ./update.sh --runtime go --backend native --dry-run cloud
bash ./uninstall.sh --runtime go --backend native cloud --dry-run
```

If a Go binary is not available locally, wrappers first try to download the matching prebuilt Go binary for the detected platform and architecture. If that download attempt is unavailable or fails, wrappers fall back to shell mode.

When `--runtime go` is selected, root wrappers auto-detect platform and choose the matching prebuilt binary name:

| Detected OS (`uname -s`) | Detected CPU (`uname -m`) | Selected artifact suffix |
| --- | --- | --- |
| `Darwin` | `x86_64`, `amd64` | `darwin-amd64` |
| `Darwin` | `arm64`, `aarch64` | `darwin-arm64` |
| `Linux` | `x86_64`, `amd64` | `linux-amd64` |
| `Linux` | `arm64`, `aarch64` | `linux-arm64` |
| `Linux` | `armv7l`, `armv7` | `linux-armv7` |
| `Linux` | `armv6l`, `armv6` | `linux-armv6` |
| `Linux` | `armv5l`, `armv5` | `linux-armv5` |
| `Linux` | `i386`, `i686` | `linux-386` |
| `Linux` | `riscv64` | `linux-riscv64` |
| `MINGW*`, `MSYS*`, `CYGWIN*` | `x86_64`, `amd64` | `windows-amd64.exe` |
| `MINGW*`, `MSYS*`, `CYGWIN*` | `arm64`, `aarch64` | `windows-arm64.exe` |
| `MINGW*`, `MSYS*`, `CYGWIN*` | `i386`, `i686` | `windows-386.exe` |

Downloaded wrapper binaries are cached under `$HOME/.tool-shed/bin` by default.

Shell-only wrappers now live under `.scripts/`:

```bash
bash ./.scripts/install.sh
bash ./.scripts/list.sh
bash ./.scripts/uninstall.sh cloud --dry-run
bash ./.scripts/update.sh --dry-run
```

### Install the helper loft only

```bash
bash ./.bash/install.sh
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bash/install.sh | bash
```

### Install a specific runtime bundle

```bash
bash ./.tools/install.sh full
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.tools/install.sh | bash -s -- full
```

### Download the compiled tool-shed binary

Phase 1 adds cross-compiled binaries under `.bin/tool-shed` so they can be committed and downloaded with `curl` from GitHub raw content.

Runtime mode selection:

- Default runtime mode is `shell`.
- Use `--runtime go` to enable the Go-owned deterministic path.
- Use `--runtime shell` (or `TOOL_SHED_RUNTIME=shell`) to force script execution.

Backend mode selection (Go runtime only):

- Default backend mode is `shell`.
- Use `--backend native` (or `TOOL_SHED_BACKEND=native`) to attempt native package-manager execution.
- Native backend currently supports Homebrew mappings on macOS, apt mappings on Linux, and winget mappings on Windows; unsupported requests fall back to shell mode.

Examples:

```bash
./tool-shed --runtime go install cloud --dry-run
./tool-shed --runtime go --backend native install cloud --dry-run
./tool-shed --runtime go --backend native update golang kubectl --dry-run
TOOL_SHED_RUNTIME=shell ./tool-shed install cloud --dry-run
```

The mixed-target example above includes a package-manager target (`golang`) and a direct-managed target (`kubectl`).
When native mode cannot cover every requested target, tool-shed automatically falls back to the shell backend to preserve verified update and safety behavior.

Supported release targets currently include:

- macOS: `darwin-amd64`, `darwin-arm64`
- Linux: `linux-amd64`, `linux-arm64`, `linux-386`, `linux-armv5`, `linux-armv6`, `linux-armv7`, `linux-riscv64`
- Windows: `windows-amd64.exe`, `windows-arm64.exe`, `windows-386.exe`

Board and legacy system mapping:

| Platform or board | Typical OS / CPU | Binary |
| --- | --- | --- |
| Raspberry Pi (older 32-bit) | Raspberry Pi OS 32-bit, ARM | `linux-armv6` or `linux-armv7` |
| Raspberry Pi (newer 64-bit) | Raspberry Pi OS 64-bit, ARM64 | `linux-arm64` |
| BeagleBone Black and similar | Linux, ARMv7 | `linux-armv7` |
| 64-bit ARM Beagle platforms | Linux, ARM64 | `linux-arm64` |
| BeagleV and other RISC-V boards | Linux, RISC-V 64 | `linux-riscv64` |
| Legacy Linux 32-bit x86 | Linux, x86 32-bit | `linux-386` |
| Legacy Windows 32-bit x86 | Windows, x86 32-bit | `windows-386.exe` |
| Legacy Linux 32-bit ARM | Linux, ARM | `linux-armv5`, `linux-armv6`, or `linux-armv7` |

Arduino note:

- Classic Arduino boards (AVR and bare-metal ARM microcontrollers) are not supported targets for this Go CLI binary.
- Linux-capable companion boards can run the Linux artifacts that match their CPU architecture.

Build artifacts and checksums:

```bash
make toolshed-release
ls ./.bin/tool-shed
cat ./.bin/tool-shed/SHA256SUMS
```

Verify downloaded artifacts:

```bash
# Example: verify Linux amd64 artifact against published checksums
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-amd64 -o tool-shed
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/SHA256SUMS -o SHA256SUMS

# Verify checksum (choose one available command)
shasum -a 256 tool-shed
grep 'tool-shed-linux-amd64' SHA256SUMS
```

Signature guidance:

- Current release verification publishes SHA256 checksums.
- Detached signatures for release artifacts are not yet published in this repository.
- Until signatures are introduced, treat checksum verification plus trusted GitHub source refs as the supported verification path.

Example downloads from `main`:

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-darwin-arm64 -o tool-shed
chmod +x ./tool-shed
./tool-shed list
```

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-amd64 -o tool-shed
chmod +x ./tool-shed
./tool-shed update --dry-run
```

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/.bin/tool-shed/tool-shed-linux-386 -o tool-shed
chmod +x ./tool-shed
./tool-shed list
```

## What is in the shed

| Domain | Location | Purpose |
| --- | --- | --- |
| Helper loft | [.bash](.bash) | Shared shell helpers and bootstrap installation for local bash workflows. |
| Tool bench | [.tools](.tools) | Bundle resolution, OS-specific installer logic, and update/uninstall orchestration. |
| Service yard | [.services](.services) | Local Docker Compose services such as PostgreSQL, Redis, RabbitMQ, MongoDB, Grafana, and Prometheus. |

The repo-root packages are intentionally modular. Each tool directory owns its own install, update, and uninstall flow, while the shared runtime keeps behavior consistent across platforms.

## Common bundles

The bundle controller supports a small set of explicit names:

- `full` — default developer setup
- `cloud` — cloud-related tooling and helpers
- `services` — local services and infrastructure support
- `ai` — AI-focused core dev tooling and package profiles
- `software-developer` — software engineering toolchain with cloud/devops CLIs
- `data-science` — analytics-oriented tooling and runtimes (no services by default)

## Quick catalog

| Area | What it is | More info |
| --- | --- | --- |
| [.bash](.bash) | Bash helper loft and shell bootstrap flow | [.bash/README.md](.bash/README.md) |
| [.tools](.tools) | Installer/runtime layer for bundles and managed updates | [.tools/README.md](.tools/README.md) |
| [.services](.services) | Local infrastructure stack for dev services | [.services/README.md](.services/README.md) |
| [aws](aws) | AWS CLI tooling and helper scripts | [AWS CLI](https://aws.amazon.com/cli/) |
| [docker](docker) | Docker CLI helpers and container workflow support | [Docker](https://www.docker.com/) |
| [git](git) | Git aliases, workflow helpers, and repo automation | [Git](https://git-scm.com/) |
| [gcloud](gcloud) | Google Cloud CLI and GCP tooling | [Google Cloud SDK](https://cloud.google.com/sdk) |
| [kubectl](kubectl) | Kubernetes CLI and operational helpers | [kubectl](https://kubernetes.io/docs/reference/kubectl/) |
| [terraform](terraform) | Infrastructure as code tooling | [Terraform](https://developer.hashicorp.com/terraform) |
| [node](node) | Node.js runtime and package-manager bootstrap | [Node.js](https://nodejs.org/) |
| [python3](python3) | Python 3 tooling and developer environment setup | [Python](https://www.python.org/) |
| [golang](golang) | Go toolchain and environment bootstrap | [Go](https://go.dev/) |

## Deep dives and project docs

- [.bash/README.md](.bash/README.md): helper loft and shell bootstrap behavior
- [.tools/README.md](.tools/README.md): install/uninstall lifecycle, bundles, and update runtime
- [.services/README.md](.services/README.md): service stack usage and local development notes
- [AGENTS.md](AGENTS.md): repo guidance for agents and automation
- [.github/copilot-instructions.md](.github/copilot-instructions.md): contributor and Copilot conventions
- [Makefile](Makefile): shared build and validation targets
- [Jenkinsfile](Jenkinsfile): CI orchestration

## Notes

- Uninstall requires an explicit tool or bundle target.
- Existing installs can be adopted before updates are applied.
- See [.tools/README.md](.tools/README.md) and [.bash/README.md](.bash/README.md) for the full runtime and installer details.

