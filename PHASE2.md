# PHASE2: Binary Owns Resolution, State, And UX Formatting

## Goal
Move deterministic control-plane logic from shell into Go while still using shell for system mutation execution.

## Why This Phase Exists
This reduces complexity and drift by centralizing resolver and state behavior in typed code, while avoiding high-risk backend rewrites yet.

## In Scope
- Port bundle definitions and aliases into Go.
- Port target expansion, canonicalization, deduplication, and order guarantees into Go.
- Port managed state read and write compatibility into Go.
- Port dry-run target rendering and progress formatting into Go.
- Keep shell as backend executor for actual installs and updates.

## Out Of Scope
- Native package manager execution.
- Native direct release download update flows.
- Removal of shell backend scripts.

## Implementation Tasks
1. Data model port
- Encode canonical bundles and alias map in Go structures.
- Maintain ordering semantics used by current scripts.

2. Resolver port
- Implement resolver from requested targets to final tool list.
- Preserve behavior for bundle names, aliases, and mixed target lists.

3. State port
- Implement read and write for managed state in existing format.
- Preserve compatibility with current shell state files.

4. UX parity
- Reproduce dry-run output for target previews.
- Reproduce progress label and summary style used by current scripts.

5. Backend bridge
- Execute shell backend with Go-resolved targets.
- Ensure requested package profile semantics remain intact.

## Validation Checklist
- Full parity tests for canonical bundles: full, cloud, services, ai, software-developer, data-science.
- Alias parity tests for known aliases.
- Mixed target list parity tests with duplicates and alias combinations.
- State read and write compatibility tests in both directions:
  - write in Go, read in shell
  - write in shell, read in Go
- Dry-run rendering regression checks.

## Risks
- Target order drift causing subtle behavior changes.
- State schema mismatch breaking update or adoption workflows.
- Message wording drift causing confusion in automation logs.

## Exit Criteria
- Go resolver and state handling produce parity with current shell behavior.
- Shell backend execution remains stable when fed by Go resolver output.
- No regression in dry-run readability and expected summaries.

## Deliverables
- Go resolver package.
- Go state package with compatibility tests.
- Binary-side dry-run and progress formatting.
- Integration bridge from Go logic to shell execution.
