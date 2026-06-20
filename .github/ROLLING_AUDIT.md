# Wizardry Rolling Audit

## Round 1
- Date: 2026-06-13
- Auditor scope: repo-grounded audit of Wizardry source, standards docs, audit surfaces, and targeted tests
- Criteria source: Wizardry core standards plus the rolling Wizardry-family audit criteria for shell purity, documentation consistency, portability, plain-text state, and category-first audit tracking

## Architecture Observed
- Wizardry is the shell-first core of the family rather than an app repo.
- The repo is overwhelmingly POSIX `sh` and already follows the `.tests/` contract broadly.
- The main audit pressure here is therefore on standards coherence, portability discipline, and audit accuracy rather than on app-shell GUI concerns.

## Result
- Pass: no

## What Passes
- No Python, Rust, or Cargo surfaces were found in the Wizardry repo during this pass.
- Test surfaces are already organized under `.tests/`, with broad coverage across spell families.
- The previously reported `pocket-dimension` undefined-function failure is no longer present in current source.
- Verified in this pass:
  - `sh .tests/psi/test-list-contacts.sh` passed

## Findings

### 1. AI-facing shell override guidance normalized during fix-it
- Severity: resolved
- Why it matters:
  - Wizardry relies on `.github/` as the canonical place where humans and agents learn safe shell patterns.
  - Contradictory guidance in that surface directly weakens consistency and can cause agents to reintroduce a known bad pattern.
- Evidence:
  - `LESSONS.md` says never wrap `builtin` in `eval`: `.github/LESSONS.md`
  - `EXEMPTIONS.md` reinforces the same rule and says the `eval` is only for the version check: `.github/EXEMPTIONS.md`
  - `SHELL_CODE_PATTERNS.md` now teaches the same pattern and does not recommend eval-wrapping `builtin`: `.github/SHELL_CODE_PATTERNS.md`
  - `SHELL_CODE_PATTERNS.md` also now matches `LESSONS.md` by refusing sourced-script completion setup through `complete`, `compdef`, or `bind`: `.github/SHELL_CODE_PATTERNS.md`
- Assessment:
  - This finding is closed for current source.

### 2. The existing audit results table is stale and currently inaccurate
- Severity: medium
- Why it matters:
  - Wizardry already has an AI-facing audit surface, so if it is stale it becomes active misinformation rather than neutral history.
  - A stale audit table undermines later rolling audits because it mixes old failures with current source truth.
- Evidence:
  - `AUDIT_RESULTS.md` still reports `spells/system/pocket-dimension` as a current failure for calling an undefined `pocket_dimension_usage()`: `.github/AUDIT_RESULTS.md:196`
  - current `pocket-dimension` source no longer contains that failure path and handles `--help` inline: `spells/system/pocket-dimension:5-23`, `spells/system/pocket-dimension:96-143`
  - `AUDIT_RESULTS.md` also still claims a README bash-example warning pinned to an outdated line reference: `.github/AUDIT_RESULTS.md:71`
  - current README location differs and the cited issue is no longer represented the same way: `README.md:48-54`
- Assessment:
  - The audit table is useful infrastructure, but it needs revalidation before it can be trusted as current evidence.

### 3. `list-contacts` depends on GNU-awk-specific behavior in a repo that claims POSIX-first portability
- Severity: medium
- Why it matters:
  - Wizardry standards explicitly reject GNU-specific command usage when a POSIX-safe path is required.
  - `list-contacts` currently uses `awk` `FPAT`, which is not portable POSIX awk behavior and is especially likely to drift across systems.
- Evidence:
  - GNU-awk-style `FPAT` usage in the spell: `spells/psi/list-contacts:32-45`
  - the repo’s audit contract explicitly calls out GNU-specific drift as a violation: `.github/AUDIT.md:34-41`, `.github/AUDIT.md:95-103`
  - the current test only covers help and empty-directory behavior, not cross-awk portability or actual vCard parsing: `.tests/psi/test-list-contacts.sh:1-45`
- Assessment:
  - The current targeted test passed, but it does not exercise the risky parsing path.
  - This is therefore both a portability problem and a test-gap problem.

## Suggested Next Moves
1. Refresh or replace `AUDIT_RESULTS.md` so it no longer presents stale failures as current facts.
2. Rewrite `spells/psi/list-contacts` to avoid GNU-awk-only parsing features, then add a test that exercises real vCard parsing rather than only the empty-directory path.

## Validation Notes
- `sh .tests/psi/test-list-contacts.sh` passed in this audit.
- I did not run the full Wizardry test suite in this pass.
- This round was a repo-and-standards audit, not a file-by-file exhaustive reread of the whole repository.
