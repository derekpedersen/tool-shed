# PHASE4: Binary-First Cutover And Compatibility Shims

## Goal
Make the binary the default user path while preserving shell compatibility and providing a clear migration runway.

## Why This Phase Exists
This phase completes productization and distribution while minimizing disruption for existing users and automation.

## In Scope
- Update root shell wrappers to prefer binary execution.
- Keep shell fallback behavior for compatibility.
- Update documentation for binary-first usage.
- Add release artifact verification guidance.
- Add CI coverage for native and fallback paths.

## Out Of Scope
- Immediate removal of all legacy shell internals.

## Implementation Tasks
1. Root wrapper cutover
- Update install.sh, update.sh, uninstall.sh, and list.sh to use binary when present.
- Fallback to legacy shell path when binary is unavailable.

2. Documentation updates
- Update README with binary install and usage examples.
- Update .tools documentation to explain backend selection and fallback.
- Document migration expectations for existing users.

3. CI and quality gates
- Add CI jobs that validate binary-native backend behavior.
- Add CI jobs that validate shell fallback behavior.
- Keep parity checks visible and enforced.

4. Release operations
- Publish cross-compiled binaries for supported targets.
- Publish checksums and signatures.
- Document verification instructions clearly.

5. Transition policy
- Add non-breaking deprecation messaging for shell-first invocations.
- Define a timeline for eventual legacy path reduction.

## Validation Checklist
- Root wrappers function correctly with and without local binary availability.
- Existing automation scripts continue working during transition.
- Release artifacts verify correctly using published checksums and signatures.
- Docs are accurate for all supported OS paths.

## Risks
- User confusion if fallback behavior is undocumented.
- CI blind spots if only one backend is tested.
- Inconsistent local environments when binary and shell versions diverge.

## Exit Criteria
- Binary-first flow is default and stable.
- Compatibility shims preserve current workflows.
- Release and verification process is repeatable and documented.

## Deliverables
- Updated root wrappers with binary preference.
- Updated docs for binary-first workflow.
- CI matrix covering native and fallback paths.
- Signed release artifacts with verification guidance.
