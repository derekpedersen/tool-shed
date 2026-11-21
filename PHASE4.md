# PHASE4: Dual-Runtime Productization

## Goal
Productize both runtime paths so users can reliably choose binary or script workflows, with native-first execution and verified shell fallback when native coverage is incomplete.

## Why This Phase Exists
This phase stabilizes release and documentation for both runtime modes while minimizing disruption for existing users and automation.

## In Scope
- Update root shell wrappers with explicit runtime selection behavior.
- Keep shell and binary modes both supported.
- Preserve automatic shell fallback for unsupported targets and parity-sensitive options.
- Update documentation for both runtime modes.
- Add release artifact verification guidance.
- Add CI coverage for native and shell paths.

## Out Of Scope
- Immediate removal of shell internals.

## Implementation Tasks
1. Root wrapper cutover
- Update install.sh, update.sh, uninstall.sh, and list.sh to support explicit runtime selection.
- Keep deterministic defaults and clear override semantics for script and binary modes.
- Ensure wrapper behavior documents and preserves fallback when native backend cannot safely complete a request.

2. Documentation updates
- Update README with binary and script usage examples.
- Update .tools documentation to explain backend selection and support guarantees.
- Document mixed-target behavior where native mode intentionally falls back to shell for verification and policy parity.
- Document operational guidance for both runtime modes.

3. CI and quality gates
- Add CI jobs that validate binary-native backend behavior.
- Add CI jobs that validate shell fallback behavior.
- Add CI assertions for fallback-triggering scenarios (unsupported target combinations and parity-sensitive flags).
- Keep parity checks visible and enforced.

4. Release operations
- Publish cross-compiled binaries for supported targets.
- Publish checksums and signatures.
- Document verification instructions clearly.

5. Transition policy
- Define long-term support policy for script and binary runtimes.
- Define criteria for changing defaults without removing either supported mode.

## Validation Checklist
- Root wrappers function correctly with and without local binary availability.
- Existing automation scripts continue working during transition.
- Mixed-target and parity-sensitive requests in native mode correctly route to shell fallback.
- Release artifacts verify correctly using published checksums and signatures.
- Docs are accurate for all supported OS paths.

## Risks
- User confusion if fallback behavior is undocumented.
- CI blind spots if only one backend is tested.
- Inconsistent local environments when binary and shell versions diverge.

## Exit Criteria
- Dual-runtime flow is stable.
- Script and binary modes are both documented and validated, including fallback triggers and expected behavior.
- Release and verification process is repeatable and documented.

## Deliverables
- Updated root wrappers with runtime selection controls.
- Updated docs for binary and script workflows.
- CI matrix covering native and shell paths, including fallback scenarios.
- Signed release artifacts with verification guidance.
