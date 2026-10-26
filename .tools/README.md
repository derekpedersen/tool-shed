# Tool Bench

Installer/runtime layer for the repo's bundle-based tool installation flow.

This folder contains the controller and platform logic that resolves bundles, dispatches module installers, and keeps the cross-platform behavior in one place. Individual tool packages continue to live as repo-root directories such as [docker](docker), [kubectl](kubectl), [aws](aws), [gcloud](gcloud), and [git](git).

Canonical bundle names are defined in `common.sh` and intentionally limited to:

- `full` (default)
- `cloud`
- `services`
- `ai`

## Files

- install.sh: central installer that resolves bundles and dispatches to module installers.
- uninstall.sh: central uninstaller that resolves bundles and dispatches to module uninstallers.
- install.ps1: PowerShell wrapper for Windows installs.
- uninstall.ps1: PowerShell wrapper for Windows uninstalls.
- update.sh / update.ps1: managed tool and bundle update controllers.
- state.sh: per-user installation source, profile, and bundle records.
- update-runtime.sh / update-download.sh: update guards and verified upstream downloads.
- update-test.sh: isolated update regression tests, run by `make test-updates`.
- common.sh: bundle definitions, alias normalization, and shared helper functions.
- module-runtime.sh: shared runtime sourced by per-module install/uninstall scripts.
- macos.sh: macOS platform install implementation used by module runtime.
- linux.sh: Linux platform install implementation used by module runtime.
- windows.sh: Windows platform install/uninstall implementation used by module runtime.

## Updating Installed Tools

Run from a repository checkout. Updating the checkout itself and refreshing shell
helpers are separate operations; the updater does not pull Git changes or modify
the `.services` Compose stack.

```bash
bash update.sh --dry-run            # Preview all recorded, installed tools
bash update.sh                      # Update those tools
bash .tools/update.sh cloud         # Only installed, managed cloud bundle members
bash .tools/update.sh git kubectl    # Selected tools, with aliases supported
bash jq/update.sh --dry-run         # Individual module, same options and guards
bash .tools/update.sh --list         # Recorded tools and requested bundles
```

Windows uses the same controller through Git Bash:

```powershell
pwsh ./.tools/update.ps1 --dry-run
pwsh ./.tools/update.ps1 cloud
pwsh ./.tools/update.ps1 jq
```

There is an `update.sh` in every installable tool module, including explicit
not-applicable results for identity, Git configuration/signing, and SSH keys.
Helper-only folders, including `cloud`, are not independent tool installations.

### Existing Installations

Older installs have no ownership records. A tool found on PATH is not automatically
considered tool-shed-managed. Explicit adoption records its existing source and
version without upgrading or installing anything:

```bash
bash update.sh --adopt cloud --dry-run
bash update.sh --adopt cloud
bash update.sh --dry-run
bash update.sh
```

Use `--adopt all` to discover all supported installed tools, including optional
ones outside the standard bundles, or name individual tools. Review the adoption
preview before opting in: distribution-provided tools can also be adopted.
Already managed tools retain their existing records. Unknown targets fail before
any updates are attempted; absent installations are skipped, never installed.

New module installs record successful newly installed tools. Pre-existing tools
are left unmanaged until adopted. Requested bundles are recorded even after a
partially successful install, with only their managed members included. Uninstall
removes a tool record only when the installation is actually gone; user-preserved
Rust/Julia installations retain their records.

State defaults to `~/.tool-shed/state`; override with `TOOL_SHED_STATE_DIR`.
Records are atomically replaced tab-separated data, never sourced as shell code.
The no-target updater uses recorded tools rather than expanding today's `full`
bundle, so newly added bundle members are never installed by an update.

### Safety And Options

- `--dry-run` performs no downloads, package metadata refreshes, logs, state writes,
	or upgrades. Candidate availability and version checks are deferred to a real run.
- Updates use targeted installed-package upgrades, not system-wide upgrades.
	Normal package dependencies may be updated by the selected package manager.
- Package major-version changes require `--allow-major`. Unknown candidate versions
	are skipped unless that override is supplied. Versioned package IDs and native
	package-manager holds/pins remain in effect.
- Docker and database/service modules require `--include-services --yes`. Take a
	backup and review migration requirements first: packages can restart services.
	The updater does not perform database migrations or backups.
- Node managed by NVM stays within the current major and advances the default alias
	only if it pointed to that version. Rust retains toolchain selections; rustup
	itself is not self-updated by native toolchain updates. Julia requires
	`--allow-major` because its selected channels may advance across major versions.
- `--with-packages` additionally updates the recorded Python, Go, and Node developer
	package profiles. This is a separate opt-in: those packages can have breaking
	changes. Python uses only the existing managed virtual environment; it never
	writes into system Python. CRAN and project dependencies are not updated.
- Adoption defaults to the `full` developer profile. Use aliases such as
	`--adopt python-ai`, `--adopt go-core`, or `--adopt node-core` to select the
	original profile. Adopting `ai` selects the corresponding AI profiles.
- A file at `~/.tool-shed/state/pins/TOOL` pins an entire module, regardless of
	`--allow-major`. Remove that file when ready to resume its updates.
- Changed executable locations or missing recorded packages cause a skip rather
	than replacement through another manager. State is user-scoped, so install and
	update as the same user; privileged commands use non-interactive sudo as needed.

```bash
bash update.sh services --dry-run --include-services --yes
bash update.sh services --include-services --yes
bash update.sh python3 golang node --with-packages
```

### Direct Installations And Limits

Linux direct updates support Go, kubectl, Helm, eksctl, doctl, yq, AWS CLI, Scala CLI,
and NVM. Downloads are isolated in temporary directories. Binary downloads require
an upstream SHA256 checksum or GitHub release-asset SHA256 digest. Missing digests,
unsupported architectures, and unknown install locations are reported as skips.
Metadata parsing requires existing `jq` and `curl`; prerequisites are never installed
by the updater. GitHub API rate limits and network errors are reported as failures.

AWS CLI requires the official AWS signing key already imported into GPG, with
fingerprint `FB5DB77FD5C118B80511ADA8A6310ACC4672475C`; signatures must match that
fingerprint. NVM updates require a clean Git checkout, verify the fetched tag object
against the official GitHub tag reference over HTTPS, and enable Git object checking.
These checks do not constitute independent release-signature verification for NVM.

Go updates preserve `/usr/local/go.tool-shed-backup`. Review and relocate that
backup before a subsequent update; existing backups are never overwritten.
Direct binary replacements are staged beside their destination before an atomic
rename. Symlinked binaries are not overwritten. Scala CLI also supports its standard
per-user installation on macOS. Other macOS tools use Homebrew or native managers.

macOS system Curl, Apple Command Line Tools, external Docker Desktop installations,
and Linux Kafka's unpacked `/opt/kafka` installation require their original manager
or a manual migration and are reported as unsupported, not silently replaced.
Configuration-only modules never regenerate credentials or keys.

### Results And Validation

Real updates use a per-user lock, refresh package metadata at most once, and log to
`~/.tool-shed/logs/update-<timestamp>-<pid>.log` (`TOOL_SHED_LOG_DIR` overrides it).
If interrupted forcibly, inspect any stale `state/update.lock` before removing it.
The controller reports successful, skipped, and failed modules, continues after
individual failures, and exits nonzero for failures. All-skipped runs return zero;
always review skip reasons. Internal module status 3 represents a deliberate skip.

```bash
make build          # Fast syntax and existing build checks
make test-updates   # Mocked updater safety tests; no real upgrades
make test           # Update tests plus existing install/uninstall dry-run coverage
```
