# Tool Shed

Tool Shed is a cross-platform installer for shell helpers, developer tools, and local service stacks on macOS, Debian-based Linux, and Windows.

The repo is split into three parts: helper scripts, installer/runtime logic, and local service setup.

## Quick start

### Run the root installer prompt

This is the interactive root installer. It asks whether to install bash helpers and whether to run the tools installer. Both default to yes, and the tools install defaults to the `full` bundle.

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/install.sh | bash
```

PowerShell / Windows users can also run the bundled wrapper:

```powershell
pwsh ./.tools/install.ps1 full
```

### List installed tools and versions

```bash
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/list.sh | bash
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
curl -fsSL https://raw.githubusercontent.com/derekpedersen/tool-shed/main/update.sh | bash
```

> Review scripts before piping remote code into Bash. Uninstall requires an explicit tool or bundle target, and updates should be previewed before real changes.

### From a repo checkout

```bash
bash ./install.sh
bash ./list.sh
bash ./uninstall.sh cloud --dry-run
bash ./update.sh --dry-run
bash ./update.sh
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

