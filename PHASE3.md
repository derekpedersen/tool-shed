# PHASE3: Native Backend Expansion (Co-Live With Scripts)

## Goal
Add native Go execution backends for install, update, uninstall, and list while preserving scripts as a permanent supported backend.

## Why This Phase Exists
This phase adds a high-performance native path without removing trusted script workflows users may prefer.

## In Scope
- Add native backend interfaces and platform adapters.
- Implement package manager execution for brew, apt, and winget paths.
- Implement native verified direct-download update flows with checksum and signature policies.
- Preserve service update safety gates and major-version policy checks.
- Keep shell backend available behind a backend selection switch.

## Out Of Scope
- Deleting shell runtime scripts.
- Forcing all users to the native backend.

## Implementation Tasks
1. Backend architecture
- Define operation interfaces for install, update, uninstall, and list.
- Add backend selector with native and shell modes.

2. Package manager adapters
- Implement macOS adapter for brew formula and cask workflows.
- Implement Linux adapter for apt workflows.
- Implement Windows adapter for winget and winget-store workflows.

3. Native direct-update flows
- Port direct tool update logic with strict HTTPS requirements.
- Port checksum verification behavior.
- Port signature verification requirements where applicable.
- Preserve path safety checks and refusal behavior.

4. Policy gates
- Preserve include-services and yes confirmation requirements.
- Preserve allow-major policy behavior.
- Preserve pin handling and skip semantics.

5. Fallback path
- Keep shell backend selectable for safe rollout, incident mitigation, and long-term co-live support.

6. Test matrix
- Add integration tests per platform and manager type.
- Include representative tools from package-managed and direct-download paths.

## Validation Checklist
- Native backend parity across supported OS and manager combinations.
- Safety policy parity for service tools and major version changes.
- Skip behavior parity with expected non-fatal skip outcomes.
- Fallback backend still works for all commands.

## Risks
- Platform-specific command nuance differences.
- Security regressions in download verification.
- Higher blast radius from backend behavior mismatches.

## Exit Criteria
- Native backend passes defined integration matrix.
- Safety and verification policies are equivalent to existing behavior.
- Shell backend remains fully available, validated, and documented as a supported runtime mode.

## Deliverables
- Native platform backend packages.
- Verification and policy enforcement modules.
- Backend selector with shell fallback option.
- Expanded integration test suite.

## Completion Status (2026-11-21)
- Implemented: backend selector with shell and native modes.
- Implemented: native package-manager adapters for Homebrew (macOS), apt (Linux), and winget or winget-store (Windows).
- Implemented: policy-gate parity in native update flow for service confirmation (`--include-services --yes`), module pin skips, and Julia major-version gate (`--allow-major`).
- Implemented: native list with no explicit targets now resolves from managed state.
- Implemented: compatibility fallback to shell backend when requested targets are not fully supported by native mode or when parity-sensitive options (for example `--with-packages`) require shell behavior.
- Co-live model remains intact: shell backend is still supported and documented as the compatibility path.

Notes:
- Verified direct-download update logic (checksums, signatures, strict HTTPS) remains enforced through shell fallback for now.
- Current test coverage includes adapter behavior and fallback/policy unit tests; full cross-platform integration matrix remains a follow-up hardening task.
