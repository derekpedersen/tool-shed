# PHASE3: Binary Owns Execution Backends

## Goal
Migrate install, update, uninstall, and list execution backends from shell to native Go adapters while preserving safety and skip policies.

## Why This Phase Exists
This phase removes the main runtime dependency on shell internals and gives full binary control over platform execution behavior.

## In Scope
- Add native backend interfaces and platform adapters.
- Implement package manager execution for brew, apt, and winget paths.
- Implement native verified direct-download update flows with checksum and signature policies.
- Preserve service update safety gates and major-version policy checks.
- Keep shell fallback available behind a backend selection switch.

## Out Of Scope
- Deleting shell runtime scripts.
- Removing fallback execution path.

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
- Keep shell backend selectable for safe rollout and incident mitigation.

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
- Shell fallback is still available and validated.

## Deliverables
- Native platform backend packages.
- Verification and policy enforcement modules.
- Backend selector with shell fallback option.
- Expanded integration test suite.
