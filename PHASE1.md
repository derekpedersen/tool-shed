# PHASE1: Binary Orchestrator

## Goal
Introduce a compiled tool-shed CLI that delegates to existing shell entrypoints with zero behavior change.

## Why This Phase Exists
This phase gives us a distributable binary quickly while preserving existing install, update, uninstall, and list behavior.

## In Scope
- Build a Go CLI entrypoint for install, update, uninstall, and list.
- Pass through all positional args and flags exactly as received.
- Inherit environment variables unchanged.
- Stream stdout and stderr from delegated scripts without rewriting output.
- Return identical exit codes from delegated scripts.
- Add cross-compile build targets for release artifacts.

## Out Of Scope
- Rewriting target resolution logic.
- Rewriting state storage logic.
- Rewriting package manager execution logic.
- Rewriting verified direct download update flows.

## Implementation Tasks
1. Create Go module and command structure
- Add go.mod and command layout under a new Go app directory.
- Add one root command and four subcommands: install, update, uninstall, list.

2. Delegate subcommands to current shell entrypoints
- install delegates to install.sh
- update delegates to update.sh
- uninstall delegates to uninstall.sh
- list delegates to list.sh
- Preserve argument ordering exactly.

3. Repo root discovery
- Resolve repository root from current working directory.
- Fail with a clear message if expected scripts are missing.

4. Process execution behavior
- Use inherited stdin, stdout, stderr.
- Inherit full environment.
- Exit with child process exit code.

5. Build and release plumbing
- Add Makefile targets for local build and cross compilation.
- Produce artifacts for macOS, Linux, and Windows.
- Include amd64 and arm64 where supported.

## Validation Checklist
- Running binary install matches shell install output and exit code for dry run and normal mode.
- Running binary update matches shell update output and exit code for dry run and normal mode.
- Running binary uninstall matches shell uninstall output and exit code for dry run and normal mode.
- Running binary list matches shell list output and exit code.
- Representative env vars still affect behavior when called via binary.

## Risks
- Arg escaping or ordering drift.
- Output buffering differences.
- Incorrect repo root detection when called from nested directories.

## Exit Criteria
- Binary is usable as a drop-in wrapper around shell entrypoints.
- Behavior parity is verified for representative scenarios.
- No existing script behavior changes are required to complete this phase.

## Deliverables
- New Go CLI wrapper implementation.
- Build targets in Makefile.
- Basic parity tests for delegation behavior.
